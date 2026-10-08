class_name DailyChunkGenerator
extends RefCounted

## Builds the endless wall chunk by chunk from a run seed. Each chunk is a hold field
## (FieldChunkPipeline) grown on top of the previous chunk's seam band, so chunks are
## built in order and cached. See docs/adr/0011-hold-field-generation.md.

const FieldChunkPipelineScript = preload("res://src/gameplay/generation/field_chunk_pipeline.gd")
const HoldReachGraphScript = preload("res://src/gameplay/generation/hold_reach_graph.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")

## A valid candidate whose easiest-route bottleneck lands this close to the band's target
## is kept without building the remaining candidates (generation runs on the main thread).
const GOOD_ENOUGH_SCORE_MISS_METERS: float = 0.2

var _tuning: GenerationTuning
var _pipeline: FieldChunkPipelineScript
var _chunk_layout_cache: Dictionary[String, GeneratedChunkLayout]
var _chunk_seam_cache: Dictionary[String, GeneratedChunkSeamValidationResult]

## static_reach_distance_meters is accepted for call-site compatibility; the hold field
## measures difficulty by move length, not by the static reach threshold.
func _init(tuning_value: GenerationTuning, static_reach_distance_meters: float = -1.0) -> void:
	Validation.require_condition(tuning_value != null, "DailyChunkGenerator requires generation tuning.")
	_tuning = tuning_value
	_tuning.assert_valid()
	var validation_tuning: RouteValidationTuningScript = _tuning.get_route_validation_tuning()
	Validation.require_condition(
		static_reach_distance_meters <= validation_tuning.max_move_distance_meters,
		"DailyChunkGenerator runtime static reach cannot exceed the swing move envelope."
	)
	_pipeline = FieldChunkPipelineScript.new(_tuning)
	_chunk_layout_cache = {}
	_chunk_seam_cache = {}

func build_chunk(seed_key: String, chunk_index: int) -> GeneratedChunkLayout:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative.")
	Validation.require_condition(
		seed_key.begins_with(_tuning.generator_version + ":"),
		"DailyChunkGenerator seed key must match the configured generator version."
	)
	for pending_chunk_index in range(_get_first_uncached_predecessor_index(seed_key, chunk_index), chunk_index + 1):
		var pending_cache_key: String = _get_chunk_cache_key(seed_key, pending_chunk_index)
		if not _chunk_layout_cache.has(pending_cache_key):
			_chunk_layout_cache[pending_cache_key] = _build_chunk(seed_key, pending_chunk_index)

	_evict_chunk_caches_before(seed_key, chunk_index - _retained_chunk_history_count())
	return _chunk_layout_cache[_get_chunk_cache_key(seed_key, chunk_index)]

func get_difficulty_band_for_chunk(chunk_index: int) -> int:
	Validation.require_condition(chunk_index >= 0, "DailyChunkGenerator chunk index cannot be negative when calculating a difficulty band.")
	return get_difficulty_band_for_height(float(chunk_index) * _tuning.segment_height_meters)

func get_difficulty_band_for_height(height_meters: float) -> int:
	Validation.require_condition(height_meters >= 0.0, "DailyChunkGenerator height cannot be negative when calculating a difficulty band.")
	if height_meters < _tuning.easy_band_max_height_meters:
		return ChunkDifficultyBand.Value.EASY
	if height_meters < _tuning.baseline_band_max_height_meters:
		return ChunkDifficultyBand.Value.BASELINE
	return ChunkDifficultyBand.Value.CHALLENGE

## Whether the next chunk's easiest route can be reached from the current chunk's seam
## band. Cached per candidate pair (audit N1: candidates of one chunk share seed + index).
func validate_chunk_seam(current_layout: GeneratedChunkLayout, next_layout: GeneratedChunkLayout) -> GeneratedChunkSeamValidationResult:
	Validation.require_condition(current_layout != null, "DailyChunkGenerator current seam layout cannot be null.")
	Validation.require_condition(next_layout != null, "DailyChunkGenerator next seam layout cannot be null.")
	Validation.require_condition(next_layout.chunk_index == current_layout.chunk_index + 1, "DailyChunkGenerator seam validation requires adjacent chunks.")
	var seam_cache_key: String = _get_chunk_seam_cache_key(current_layout, next_layout)
	if _chunk_seam_cache.has(seam_cache_key):
		return _chunk_seam_cache[seam_cache_key]

	var segment_height: float = _tuning.segment_height_meters
	var positions: PackedVector2Array = PackedVector2Array()
	var sizes: PackedVector2Array = PackedVector2Array()
	var hold_ids: PackedStringArray = PackedStringArray()
	var sources: PackedInt32Array = PackedInt32Array()
	var lowest_seam_y: float = -(segment_height - _tuning.seam_band_height_meters)
	for handhold in current_layout.handholds:
		if handhold.local_position.y <= lowest_seam_y:
			var _s: bool = sources.append(positions.size())
			var _p: bool = positions.append(handhold.local_position + Vector2(0.0, segment_height))
			var _z: bool = sizes.append(handhold.physical_size_meters)
			var _i: bool = hold_ids.append(String(handhold.hold_id))
	var entry_id: String = next_layout.route_entry_hold_ids[0]
	var entry_node: int = -1
	for handhold in next_layout.handholds:
		if String(handhold.hold_id) == entry_id:
			entry_node = positions.size()
		var _p: bool = positions.append(handhold.local_position)
		var _z: bool = sizes.append(handhold.physical_size_meters)
		var _i: bool = hold_ids.append(String(handhold.hold_id))
	Validation.require_condition(entry_node != -1, "DailyChunkGenerator next chunk entry hold is missing.")

	var result: GeneratedChunkSeamValidationResult
	var from_hold_id: StringName = StringName(current_layout.route_exit_hold_ids[0])
	if sources.is_empty():
		result = GeneratedChunkSeamValidationResult.new(false, "Current chunk has no holds in its seam band.", current_layout.chunk_index, next_layout.chunk_index, from_hold_id, StringName(entry_id))
	else:
		var validation_tuning: RouteValidationTuningScript = _tuning.get_route_validation_tuning()
		var graph: HoldReachGraphScript = HoldReachGraphScript.new(positions, sizes, validation_tuning.max_move_distance_meters, validation_tuning.max_downward_move_meters)
		var is_entry: PackedByteArray = graph.empty_mask()
		is_entry[entry_node] = 1
		var path: PackedInt32Array = graph.path_within(sources, is_entry, graph.empty_mask(), INF)
		if path.is_empty():
			result = GeneratedChunkSeamValidationResult.new(false, "Next chunk entry is not reachable from the current chunk's seam band.", current_layout.chunk_index, next_layout.chunk_index, from_hold_id, StringName(entry_id))
		else:
			result = GeneratedChunkSeamValidationResult.new(true, "", current_layout.chunk_index, next_layout.chunk_index, StringName(hold_ids[path[0]]), StringName(entry_id))
	_chunk_seam_cache[seam_cache_key] = result
	return result

## Tries candidates until one is close enough to the band target (else keeps the best), and falls
## back to one relaxed attempt (EASY field, no hazards, one route fewer) through the same
## validation, with a warning. A chunk that still fails is a hard error: the wall never
## ships with a gap.
func _build_chunk(seed_key: String, chunk_index: int) -> GeneratedChunkLayout:
	var previous_layout: GeneratedChunkLayout = null
	if chunk_index > 0:
		previous_layout = _chunk_layout_cache[_get_chunk_cache_key(seed_key, chunk_index - 1)]
	var difficulty_band: int = get_difficulty_band_for_chunk(chunk_index)
	var attempt_count: int = _tuning.route_validation_candidate_attempt_count
	var best: GeneratedChunkLayout = null
	var failure_reasons: PackedStringArray = PackedStringArray()
	for attempt_index in range(attempt_count):
		var candidate: GeneratedChunkLayout = _build_chunk_candidate(seed_key, chunk_index, attempt_index, previous_layout, difficulty_band, false)
		if candidate == null:
			var _f: bool = failure_reasons.append("attempt %d: %s" % [attempt_index, _pipeline.last_failure_reason])
			continue
		if best == null or candidate.candidate_score > best.candidate_score:
			best = candidate
		if best.candidate_score >= -GOOD_ENOUGH_SCORE_MISS_METERS:
			break
	if best == null:
		best = _build_chunk_candidate(seed_key, chunk_index, attempt_count, previous_layout, difficulty_band, true)
		if best == null:
			var _r: bool = failure_reasons.append("relaxed: %s" % _pipeline.last_failure_reason)
		else:
			push_warning("DailyChunkGenerator used the relaxed fallback for chunk %d of %s: %s" % [chunk_index, seed_key, "; ".join(failure_reasons)])
	Validation.require_condition(best != null, "DailyChunkGenerator could not build chunk %d: %s" % [chunk_index, "; ".join(failure_reasons)])
	return best

func _build_chunk_candidate(
	seed_key: String,
	chunk_index: int,
	attempt_index: int,
	previous_layout: GeneratedChunkLayout,
	difficulty_band: int,
	relaxed: bool
) -> GeneratedChunkLayout:
	return _pipeline.build_layout(seed_key, chunk_index, difficulty_band, attempt_index, previous_layout, relaxed)

## Walks back from chunk_index only as far as the nearest cached chunk; each chunk grows
## from its predecessor's seam band.
func _get_first_uncached_predecessor_index(seed_key: String, chunk_index: int) -> int:
	var earliest_required_index: int = chunk_index
	while earliest_required_index > 0 and not _chunk_layout_cache.has(_get_chunk_cache_key(seed_key, earliest_required_index - 1)):
		earliest_required_index -= 1
	return earliest_required_index

## Chunks kept behind the highest built index: the coordinator's keep-behind window plus
## its spawn-ahead reach, so a steady climb never rebuilds a retired chunk.
func _retained_chunk_history_count() -> int:
	return _tuning.chunk_keep_behind_count + _tuning.chunk_spawn_ahead_count + 1

func _evict_chunk_caches_before(seed_key: String, min_retained_chunk_index: int) -> void:
	if min_retained_chunk_index <= 0:
		return
	for cache_key: String in _chunk_layout_cache.keys():
		if _is_stale_key(cache_key, seed_key, min_retained_chunk_index):
			var _erased: bool = _chunk_layout_cache.erase(cache_key)
	for cache_key: String in _chunk_seam_cache.keys():
		if _is_stale_key(cache_key, seed_key, min_retained_chunk_index):
			var _erased: bool = _chunk_seam_cache.erase(cache_key)

## Cache keys are "<seed>|<chunk index>|..."; stale when from another run or below the window.
func _is_stale_key(cache_key: String, seed_key: String, min_retained_chunk_index: int) -> bool:
	if not cache_key.begins_with(seed_key + "|"):
		return true
	var index_text: String = cache_key.substr(seed_key.length() + 1).get_slice("|", 0)
	return index_text.to_int() < min_retained_chunk_index

func _get_chunk_cache_key(seed_key: String, chunk_index: int) -> String:
	return "%s|%d" % [seed_key, chunk_index]

func _get_chunk_seam_cache_key(current_layout: GeneratedChunkLayout, next_layout: GeneratedChunkLayout) -> String:
	return "%s|%d|%d|%d|%d" % [
		current_layout.seed_key,
		current_layout.chunk_index,
		current_layout.selected_candidate_attempt_index,
		next_layout.chunk_index,
		next_layout.selected_candidate_attempt_index,
	]
