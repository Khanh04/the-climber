class_name FieldChunkPipeline
extends RefCounted

## Builds one chunk as a hold field (docs/adr/0011-hold-field-generation.md):
## sample holds along wandering corridors -> reachability graph over this chunk plus the
## previous chunk's seam band -> require K distinct routes within the band's move limit,
## filling gaps on the best near-miss route when short -> decorate types, coins, hazards
## -> emit GeneratedChunkLayout. Returns null (with last_failure_reason) when the field
## cannot offer K routes; never emits an invalid layout.

const BandFieldProfileScript = preload("res://resources/config/band_field_profile.gd")
const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const FieldChunkDecoratorScript = preload("res://src/gameplay/generation/field_chunk_decorator.gd")
const HandholdLifecycleRuleScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HoldFieldSamplerScript = preload("res://src/gameplay/generation/hold_field_sampler.gd")
const HoldReachGraphScript = preload("res://src/gameplay/generation/hold_reach_graph.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")

## In chunk 0 every route shares the starter holds, so nodes this low are never banned
## when counting distinct routes.
const OPENER_SHARED_START_METERS: float = 3.0
const STARTER_HOLD_HALF_SPACING_METERS: float = 0.8
const MAX_REPAIR_PASSES: int = 6
## Gap-filling holds may sit this close to existing holds.
const REPAIR_MIN_SPACING_METERS: float = 0.35
const REPAIR_SIDESTEP_METERS: float = 0.35
## Repair may add this many holds beyond the profile's sampling budget.
const REPAIR_HOLD_ALLOWANCE: int = 24
const REPAIR_FLOOR_CLEARANCE_METERS: float = 0.1
## Spine holds are laid this fraction of the band move limit apart.
const SPINE_STEP_FRACTION: float = 0.8
## Pruning keeps each route continued up into this top slice, where the next chunk starts.
const TOP_EXTENSION_BAND_METERS: float = 1.2
## A corridor's band for repair: its half-width plus this slack.
const CORRIDOR_BAND_SLACK_METERS: float = 0.6
## Graph hold size used before types are known: the smallest catalog hold, so gaps are
## measured conservatively.
const CONSERVATIVE_HOLD_SIZE: Vector2 = Vector2(0.12, 0.28)

var last_failure_reason: String = ""

var _tuning: GenerationTuning

func _init(tuning_value: GenerationTuning) -> void:
	Validation.require_condition(tuning_value != null, "FieldChunkPipeline requires generation tuning.")
	_tuning = tuning_value

func build_layout(
	seed_key: String,
	chunk_index: int,
	difficulty_band: int,
	candidate_attempt_index: int,
	previous_layout: GeneratedChunkLayout,
	relaxed: bool
) -> GeneratedChunkLayout:
	Validation.require_condition(seed_key != "", "FieldChunkPipeline requires a seed key.")
	Validation.require_condition(chunk_index >= 0, "FieldChunkPipeline chunk index cannot be negative.")
	Validation.require_condition(chunk_index == 0 or previous_layout != null, "FieldChunkPipeline requires the previous chunk for chunk %d." % chunk_index)
	ChunkDifficultyBandScript.assert_valid(difficulty_band)
	last_failure_reason = ""

	var is_opener: bool = chunk_index == 0
	var profile: BandFieldProfileScript = _tuning.get_field_profile(ChunkDifficultyBandScript.Value.EASY if relaxed else difficulty_band)
	var validation_tuning: RouteValidationTuningScript = _tuning.get_route_validation_tuning()
	var segment_height: float = _tuning.segment_height_meters
	var start_height: float = float(chunk_index) * segment_height
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = DeterministicHash.of_string("%s:field:%d:%d" % [seed_key, chunk_index, candidate_attempt_index])

	# Graph nodes [0, first_new_node) are the previous chunk's seam band (shifted into this
	# chunk's frame); they are route sources and spacing anchors but are not emitted.
	var seam_positions: PackedVector2Array = _previous_seam_positions(previous_layout, segment_height)
	var new_positions: PackedVector2Array = PackedVector2Array()
	var min_hold_height: float = 0.15
	if is_opener:
		var starter_height: float = _tuning.opener_first_row_height_meters
		var _l: bool = new_positions.append(Vector2(-STARTER_HOLD_HALF_SPACING_METERS, -starter_height))
		var _r: bool = new_positions.append(Vector2(STARTER_HOLD_HALF_SPACING_METERS, -starter_height))
		min_hold_height = starter_height
	var fixed_points: PackedVector2Array = seam_positions.duplicate()
	fixed_points.append_array(new_positions)
	var sampler: HoldFieldSamplerScript = HoldFieldSamplerScript.new(seed_key, _tuning.get_half_usable_width_meters())
	new_positions.append_array(sampler.sample(profile, start_height, segment_height, min_hold_height, fixed_points, rng, profile.max_hold_count - new_positions.size()))

	var first_new_node: int = seam_positions.size()
	var sources: PackedInt32Array = PackedInt32Array()
	if is_opener:
		sources = PackedInt32Array([0, 1])
	else:
		for node in range(first_new_node):
			var _s: bool = sources.append(node)
	if sources.is_empty():
		last_failure_reason = "previous chunk left no seam holds"
		return null

	var max_move: float = profile.max_route_move_meters
	# The relaxed fallback (an EASY field without hazards) also accepts one route fewer than
	# the band asks for, so a rare unlucky seed degrades instead of stopping the run.
	var required: int = maxi(1, _tuning.get_field_profile(difficulty_band).required_route_count - 1) if relaxed else profile.required_route_count
	var graph: HoldReachGraphScript = _build_pruned_graph(seam_positions, new_positions, sources, validation_tuning)
	new_positions = _new_positions_of(graph, first_new_node)
	var routes: Array[PackedInt32Array] = []
	for _pass in range(MAX_REPAIR_PASSES + 1):
		var is_target: PackedByteArray = _targets(graph, first_new_node, segment_height)
		var exempt: PackedByteArray = _exempt(graph, first_new_node, sources, is_opener)
		routes = graph.distinct_routes(sources, is_target, exempt, max_move, _tuning.route_separation_meters, required, PackedByteArray(), _corridor_guides(graph, sampler, profile, start_height, exempt))
		if routes.size() >= required:
			break
		var gap_fill: PackedVector2Array = _corridor_fill_points(graph, sampler, profile, start_height, sources, is_target, exempt, max_move)
		if gap_fill.is_empty():
			gap_fill = _gap_fill_points(graph, routes, sources, is_target, exempt, max_move)
		if gap_fill.is_empty() or new_positions.size() + gap_fill.size() > profile.max_hold_count + REPAIR_HOLD_ALLOWANCE:
			break
		var hold_count_before: int = new_positions.size()
		new_positions.append_array(gap_fill)
		graph = _build_pruned_graph(seam_positions, new_positions, sources, validation_tuning)
		new_positions = _new_positions_of(graph, first_new_node)
		if new_positions.size() == hold_count_before:
			break # every suggested hold was unreachable and pruned; repair is stuck

	if routes.size() < required:
		var route_xs: PackedStringArray = PackedStringArray()
		for route in routes:
			var _x: bool = route_xs.append("%.1f" % graph.positions[route[route.size() / 2]].x)
		var target_count: int = _targets(graph, first_new_node, segment_height).count(1)
		last_failure_reason = "only %d of %d distinct routes within %.2f m moves (holds %d, sources %d, targets %d, route mid x [%s])" % [
			routes.size(), required, max_move, graph.node_count() - first_new_node, sources.size(), target_count, ", ".join(route_xs)
		]
		return null

	# Prune: keep every route hold and a share of the rest, preferring holds that link
	# routes, then make sure the routes survived (they keep all their holds, so they should).
	var easiest_before_prune: PackedInt32Array = graph.easiest_path(sources, _targets(graph, first_new_node, segment_height), graph.empty_mask(), max_move)
	new_positions = _prune_to_routes(graph, first_new_node, routes, easiest_before_prune, sources, profile, segment_height, rng)
	graph = _build_pruned_graph(seam_positions, new_positions, sources, validation_tuning)
	var pruned_exempt: PackedByteArray = _exempt(graph, first_new_node, sources, is_opener)
	routes = graph.distinct_routes(
		sources, _targets(graph, first_new_node, segment_height), pruned_exempt, max_move, _tuning.route_separation_meters, required,
		PackedByteArray(), _corridor_guides(graph, sampler, profile, start_height, pruned_exempt)
	)
	if routes.size() < required:
		last_failure_reason = "pruning left %d of %d distinct routes" % [routes.size(), required]
		return null

	var final_targets: PackedByteArray = _targets(graph, first_new_node, segment_height)
	var final_exempt: PackedByteArray = _exempt(graph, first_new_node, sources, is_opener)
	# routes[0] is the easiest route overall (the layout's safe path); the distinct routes follow.
	var easiest: PackedInt32Array = graph.easiest_path(sources, final_targets, graph.empty_mask(), max_move)
	Validation.require_condition(not easiest.is_empty(), "FieldChunkPipeline found distinct routes but no easiest route.")
	var decorated_routes: Array[PackedInt32Array] = [easiest]
	for route in routes:
		if route != easiest:
			decorated_routes.append(route)
	routes = decorated_routes
	var decorator: FieldChunkDecoratorScript = FieldChunkDecoratorScript.new()
	var hazard_count: int = 0 if relaxed or is_opener else profile.hazard_count
	decorator.decorate(
		graph, first_new_node, routes, sources, final_targets, final_exempt, _corridor_guides(graph, sampler, profile, start_height, final_exempt), difficulty_band, is_opener, profile,
		hazard_count, max_move, _tuning.route_separation_meters, _tuning.get_half_usable_width_meters(), segment_height, rng
	)
	var easiest_bottleneck: float = graph.bottleneck_of(routes[0])
	var target_move: float = (profile.min_easiest_route_move_meters + max_move) * 0.5
	return _emit_layout(seed_key, chunk_index, difficulty_band, start_height, candidate_attempt_index, graph, first_new_node, routes, decorator, -absf(easiest_bottleneck - target_move))

## Keeps every hold on a counted route (and the easiest route, the opener's starter holds,
## and each route's continuation to the top of the chunk), plus extra_hold_keep_ratio of the others ranked by how
## useful they are: a hold within one move of two routes links them (score 2), one within
## a move of one route scores 1, the rest 0. Ties are
## broken by the candidate's seeded shuffle. Returns the kept new holds in original order.
func _prune_to_routes(
	graph: HoldReachGraphScript,
	first_new_node: int,
	routes: Array[PackedInt32Array],
	easiest: PackedInt32Array,
	sources: PackedInt32Array,
	profile: BandFieldProfileScript,
	segment_height: float,
	rng: RandomNumberGenerator
) -> PackedVector2Array:
	var keep: PackedByteArray = graph.empty_mask()
	for node in easiest:
		keep[node] = 1
	# Alternative routes only keep the holds they need within the band's move limit; the
	# easiest route keeps every hold, so difficulty and the safe path do not change.
	for route in routes:
		for node in graph.shortcut_route(route, profile.max_route_move_meters):
			keep[node] = 1
	for source in sources:
		keep[source] = 1

	# Routes stop at the first hold of the seam band, but the next chunk grows from the top
	# of this one: continue each route to the top metre within the band's move limit. If a
	# route cannot be continued, keep the whole seam band instead.
	var reach: float = profile.max_route_move_meters
	# Every hold in that top slice stays too: they are the next chunk's starting holds.
	var is_top: PackedByteArray = graph.empty_mask()
	for node in range(first_new_node, graph.node_count()):
		if graph.positions[node].y <= -(segment_height - TOP_EXTENSION_BAND_METERS):
			is_top[node] = 1
			keep[node] = 1
	for route in routes + [easiest]:
		var typed_route: PackedInt32Array = route
		var extension: PackedInt32Array = graph.path_within(PackedInt32Array([typed_route[typed_route.size() - 1]]), is_top, graph.empty_mask(), reach)
		if extension.is_empty():
			var seam_floor: float = -(segment_height - _tuning.seam_band_height_meters)
			for node in range(first_new_node, graph.node_count()):
				if graph.positions[node].y <= seam_floor:
					keep[node] = 1
		for node in extension:
			keep[node] = 1
	var extras: Array[Vector2i] = [] # (score, node)
	for node in range(first_new_node, graph.node_count()):
		if keep[node] == 1:
			continue
		var point: Vector2 = graph.positions[node]
		var routes_in_reach: int = 0
		for route in routes:
			for route_node in route:
				if graph.positions[route_node].distance_to(point) <= reach:
					routes_in_reach += 1
					break
		var score: int = mini(routes_in_reach, 2)
		extras.append(Vector2i(score, node))
	# Seeded shuffle first, then a stable sort by score, so equal scores keep the shuffle order.
	for index in range(extras.size() - 1, 0, -1):
		var swap: int = rng.randi_range(0, index)
		var held: Vector2i = extras[index]
		extras[index] = extras[swap]
		extras[swap] = held
	var by_score: Array[Vector2i] = []
	for score in [2, 1, 0]:
		for extra in extras:
			if extra.x == score:
				by_score.append(extra)
	var keep_count: int = roundi(profile.extra_hold_keep_ratio * float(extras.size()))
	for index in range(keep_count):
		keep[by_score[index].y] = 1
	# Every kept hold must stay reachable once the others are gone: also keep the chain that
	# reaches it from the sources through as few dropped holds as possible.
	var parents: PackedInt32Array = graph.cheapest_parent_tree(sources, keep)
	for node in range(first_new_node, graph.node_count()):
		if keep[node] == 0:
			continue
		var step: int = parents[node]
		while step >= 0 and keep[step] == 0:
			keep[step] = 1
			step = parents[step]

	var kept: PackedVector2Array = PackedVector2Array()
	for node in range(first_new_node, graph.node_count()):
		if keep[node] == 1:
			var _a: bool = kept.append(graph.positions[node])
	return kept

## The previous chunk's holds in its top seam band, moved into this chunk's frame (they sit
## just below this chunk's floor, y > 0).
func _previous_seam_positions(previous_layout: GeneratedChunkLayout, segment_height: float) -> PackedVector2Array:
	var seam: PackedVector2Array = PackedVector2Array()
	if previous_layout == null:
		return seam
	var lowest_seam_y: float = -(segment_height - _tuning.seam_band_height_meters)
	for handhold in previous_layout.handholds:
		if handhold.local_position.y <= lowest_seam_y:
			var _a: bool = seam.append(handhold.local_position + Vector2(0.0, segment_height))
	return seam

## Graph over seam + new holds, dropping new holds nobody can reach from the sources.
func _build_pruned_graph(seam_positions: PackedVector2Array, new_positions: PackedVector2Array, sources: PackedInt32Array, validation_tuning: RouteValidationTuningScript) -> HoldReachGraphScript:
	var all_positions: PackedVector2Array = seam_positions.duplicate()
	all_positions.append_array(new_positions)
	var graph: HoldReachGraphScript = _graph_over(all_positions, validation_tuning)
	var reached: PackedByteArray = graph.reachable_from(sources)
	var kept: PackedVector2Array = seam_positions.duplicate()
	for index in range(new_positions.size()):
		if reached[seam_positions.size() + index] == 1:
			var _a: bool = kept.append(new_positions[index])
	if kept.size() == all_positions.size():
		return graph
	return _graph_over(kept, validation_tuning)

func _graph_over(all_positions: PackedVector2Array, validation_tuning: RouteValidationTuningScript) -> HoldReachGraphScript:
	var sizes: PackedVector2Array = PackedVector2Array()
	var _resize: int = sizes.resize(all_positions.size())
	sizes.fill(CONSERVATIVE_HOLD_SIZE)
	return HoldReachGraphScript.new(all_positions, sizes, validation_tuning.max_move_distance_meters, validation_tuning.max_downward_move_meters)

func _new_positions_of(graph: HoldReachGraphScript, first_new_node: int) -> PackedVector2Array:
	return graph.positions.slice(first_new_node)

## Route targets: this chunk's seam band, which the next chunk grows from.
func _targets(graph: HoldReachGraphScript, first_new_node: int, segment_height: float) -> PackedByteArray:
	var is_target: PackedByteArray = graph.empty_mask()
	for node in range(first_new_node, graph.node_count()):
		if graph.positions[node].y <= -(segment_height - _tuning.seam_band_height_meters):
			is_target[node] = 1
	return is_target

func _exempt(graph: HoldReachGraphScript, first_new_node: int, sources: PackedInt32Array, is_opener: bool) -> PackedByteArray:
	var exempt: PackedByteArray = graph.empty_mask()
	for source in sources:
		exempt[source] = 1
	if is_opener:
		for node in range(first_new_node, graph.node_count()):
			if graph.positions[node].y > -OPENER_SHARED_START_METERS:
				exempt[node] = 1
	return exempt

## Routes are meant to follow the corridors. For every corridor with no climbable path
## inside its band, take the best path inside the band ignoring the move limit and add a
## hold in the middle of each move on it that is too long. A corridor broken by a fade
## has no path inside its band and is left alone (that gap is the intended traverse).
func _corridor_fill_points(
	graph: HoldReachGraphScript,
	sampler: HoldFieldSamplerScript,
	profile: BandFieldProfileScript,
	start_height: float,
	sources: PackedInt32Array,
	is_target: PackedByteArray,
	exempt: PackedByteArray,
	max_move: float
) -> PackedVector2Array:
	var fill: PackedVector2Array = PackedVector2Array()
	var guides: Array[PackedByteArray] = _corridor_guides(graph, sampler, profile, start_height, exempt)
	for corridor_index in range(guides.size()):
		var outside_band: PackedByteArray = guides[corridor_index]
		if not graph.path_within(sources, is_target, outside_band, max_move).is_empty():
			continue
		var near_miss: PackedInt32Array = graph.easiest_path(sources, is_target, outside_band, INF)
		if near_miss.is_empty():
			_append_corridor_spine(graph, sampler, profile, corridor_index, start_height, max_move, fill)
		else:
			_append_midpoints(graph, near_miss, max_move, fill)
	return fill

## A corridor with no connected path at all: lay holds up its centre line wherever the
## corridor is intact and no hold is already within half a move. Fade gaps are skipped:
## those are the intended traverses.
func _append_corridor_spine(graph: HoldReachGraphScript, sampler: HoldFieldSamplerScript, profile: BandFieldProfileScript, corridor_index: int, start_height: float, max_move: float, fill: PackedVector2Array) -> void:
	var step: float = max_move * SPINE_STEP_FRACTION
	var y: float = -REPAIR_FLOOR_CLEARANCE_METERS - step * 0.5
	while y > -_tuning.segment_height_meters:
		var world_height: float = start_height - y
		if sampler.corridor_strength(corridor_index, profile.corridor_count, world_height) > 0.0:
			var point: Vector2 = Vector2(sampler.corridor_x(corridor_index, world_height), y)
			if _clear_of(point, graph.positions, max_move * 0.5) and _clear_of(point, fill, REPAIR_MIN_SPACING_METERS):
				var _a: bool = fill.append(point)
		y -= step

## One mask per corridor banning every non-exempt hold outside that corridor's band.
func _corridor_guides(graph: HoldReachGraphScript, sampler: HoldFieldSamplerScript, profile: BandFieldProfileScript, start_height: float, exempt: PackedByteArray) -> Array[PackedByteArray]:
	var band_half_width: float = profile.corridor_half_width_meters + CORRIDOR_BAND_SLACK_METERS
	var guides: Array[PackedByteArray] = []
	for corridor_index in range(profile.corridor_count):
		var outside_band: PackedByteArray = graph.empty_mask()
		for node in range(graph.node_count()):
			var point: Vector2 = graph.positions[node]
			if exempt[node] == 0 and absf(point.x - sampler.corridor_x(corridor_index, start_height - point.y)) > band_half_width:
				outside_band[node] = 1
		guides.append(outside_band)
	return guides

## When a chunk is short of routes: ban the corridors of the routes found so far, find the
## best remaining path ignoring the move limit, and add a hold in the middle of each move
## on it that is too long.
func _gap_fill_points(graph: HoldReachGraphScript, routes: Array[PackedInt32Array], sources: PackedInt32Array, is_target: PackedByteArray, exempt: PackedByteArray, max_move: float) -> PackedVector2Array:
	var banned: PackedByteArray = graph.empty_mask()
	for route in routes:
		graph.ban_corridor(route, _tuning.route_separation_meters, exempt, banned)
	var near_miss: PackedInt32Array = graph.easiest_path(sources, is_target, banned, INF)
	var fill: PackedVector2Array = PackedVector2Array()
	_append_midpoints(graph, near_miss, max_move, fill)
	return fill

## Adds evenly spaced holds inside every move on the path longer than max_move.
func _append_midpoints(graph: HoldReachGraphScript, path: PackedInt32Array, max_move: float, fill: PackedVector2Array) -> void:
	for index in range(1, path.size()):
		var a: Vector2 = graph.positions[path[index - 1]]
		var b: Vector2 = graph.positions[path[index]]
		var steps: int = ceili(a.distance_to(b) / max_move) - 1
		var sideways: Vector2 = (b - a).orthogonal().normalized() * REPAIR_SIDESTEP_METERS
		for step in range(steps):
			var midpoint: Vector2 = a.lerp(b, float(step + 1) / float(steps + 1))
			# Try the midpoint, then a small sidestep either way: a hold outside the band can
			# sit right on the midpoint without being usable for this route.
			for point in [midpoint, midpoint + sideways, midpoint - sideways]:
				var typed_point: Vector2 = point
				# Repair may reach down into the previous chunk's seam band (a too-long seam move
				# is a gap like any other) but never below it or above this chunk.
				if typed_point.y > _tuning.seam_band_height_meters or typed_point.y < -_tuning.segment_height_meters:
					continue
				if _clear_of(typed_point, graph.positions, REPAIR_MIN_SPACING_METERS) and _clear_of(typed_point, fill, REPAIR_MIN_SPACING_METERS):
					var _a: bool = fill.append(typed_point)
					break

func _clear_of(point: Vector2, others: PackedVector2Array, min_distance: float) -> bool:
	for other in others:
		if other.distance_to(point) < min_distance:
			return false
	return true

func _emit_layout(
	seed_key: String,
	chunk_index: int,
	difficulty_band: int,
	start_height: float,
	candidate_attempt_index: int,
	graph: HoldReachGraphScript,
	first_new_node: int,
	routes: Array[PackedInt32Array],
	decorator: FieldChunkDecoratorScript,
	candidate_score: float
) -> GeneratedChunkLayout:
	var handholds: Array[GeneratedHandholdSocket] = []
	for node in range(first_new_node, graph.node_count()):
		handholds.append(_build_socket(_hold_id(chunk_index, node - first_new_node), graph.positions[node], decorator.hold_types[node], decorator.hold_roles[node]))

	var safe_path_hold_ids: PackedStringArray = PackedStringArray()
	for node in routes[0]:
		if node >= first_new_node:
			var _a: bool = safe_path_hold_ids.append(_hold_id(chunk_index, node - first_new_node))
	Validation.require_condition(not safe_path_hold_ids.is_empty(), "FieldChunkPipeline easiest route must use this chunk's holds.")

	var pickups: Array[GeneratedPickupSocket] = []
	for index in range(decorator.coin_positions.size()):
		pickups.append(GeneratedPickupSocket.new(StringName("chunk_%02d_coin_%d" % [chunk_index, index]), decorator.coin_positions[index]))
	var hazards: Array[GeneratedHazardSocket] = []
	for index in range(decorator.hazard_kinds.size()):
		hazards.append(GeneratedHazardSocket.new(StringName("chunk_%02d_hazard_%d" % [chunk_index, index]), decorator.hazard_kinds[index], decorator.hazard_positions[index]))

	var entry_ids: PackedStringArray = PackedStringArray([safe_path_hold_ids[0]])
	var exit_ids: PackedStringArray = PackedStringArray([safe_path_hold_ids[safe_path_hold_ids.size() - 1]])
	var validation_result: GeneratedRouteValidationResult = GeneratedRouteValidationResult.new(true, "", StringName(exit_ids[0]), safe_path_hold_ids)
	return GeneratedChunkLayout.new(
		seed_key,
		_tuning.generator_version,
		chunk_index,
		ChunkType.Value.FORK if routes.size() >= 3 else ChunkType.Value.SPARSE_REACH,
		ChunkRouteSlot.Value.OPENER if chunk_index == 0 else ChunkRouteSlot.Value.BASELINE,
		difficulty_band,
		start_height,
		handholds,
		pickups,
		hazards,
		entry_ids,
		exit_ids,
		validation_result,
		candidate_attempt_index,
		candidate_score,
		safe_path_hold_ids
	)

func _build_socket(hold_id: StringName, position: Vector2, handhold_type: int, route_role: int) -> GeneratedHandholdSocket:
	var definition: HandholdTypeDefinitionScript = _tuning.get_required_handhold_definition(handhold_type)
	var surface_profile: HandholdSurfaceProfileScript = definition.surface_profile as HandholdSurfaceProfileScript
	var lifecycle_rule: HandholdLifecycleRuleScript = definition.lifecycle_rule as HandholdLifecycleRuleScript
	var movement_rule: HandholdMovementRuleScript = definition.movement_rule as HandholdMovementRuleScript
	return GeneratedHandholdSocket.new(
		hold_id,
		definition.definition_id,
		position,
		handhold_type,
		surface_profile.stamina_drain_multiplier,
		definition.physical_size_meters,
		lifecycle_rule.break_after_attach_seconds,
		lifecycle_rule.breaks_on_release,
		movement_rule.release_impulse_vector,
		route_role
	)

func _hold_id(chunk_index: int, hold_index: int) -> StringName:
	return StringName("chunk_%02d_hold_%03d" % [chunk_index, hold_index])
