class_name HoldFieldSampler
extends RefCounted

## Scatters holds across the full wall width. Most holds cluster along a few wandering
## route corridors; a sparse scatter between them connects corridors for traverses.
##
## Corridors are smooth functions of world height seeded from the run seed only, so they
## continue across chunk seams no matter which candidate a chunk picks. Each corridor
## drifts sideways, crosses its neighbours, and fades out for stretches (a broken
## corridor forces a traverse), which is where the choices come from.

const BandFieldProfileScript = preload("res://resources/config/band_field_profile.gd")

const MAX_CORRIDORS: int = 4
const CORRIDOR_DARTS_PER_STEP: int = 6
const SCATTER_DART_COUNT: int = 220
## Chunk 0 pulls every corridor toward the starter holds below this height, then fans out.
const OPENER_FAN_OUT_HEIGHT_METERS: float = 6.0
const FADE_SEGMENT_METERS: float = 36.0
const MIN_CORRIDOR_GAP_METERS: float = 2.6

var _run_seed_key: String
var _half_width: float
## Per-corridor seeded constants, computed once: name -> one value per corridor.
var _params: Dictionary[String, PackedFloat32Array] = {}

func _init(run_seed_key: String, half_usable_width_meters: float) -> void:
	Validation.require_condition(run_seed_key != "", "HoldFieldSampler requires a run seed key.")
	Validation.require_condition(half_usable_width_meters > 1.0, "HoldFieldSampler requires a usable wall width.")
	_run_seed_key = run_seed_key
	_half_width = half_usable_width_meters
	for spec in [["a1", 0.9, 1.8], ["p1", 14.0, 30.0], ["f1", 0.0, TAU], ["a2", 0.3, 0.7], ["p2", 4.0, 8.0], ["f2", 0.0, TAU], ["p3", 9.0, 17.0], ["f3", 0.0, TAU]]:
		var name: String = spec[0]
		var low: float = spec[1]
		var high: float = spec[2]
		var values: PackedFloat32Array = PackedFloat32Array()
		for corridor_index in range(MAX_CORRIDORS):
			var _a: bool = values.append(lerpf(low, high, DeterministicHash.unit_float("%s:corridor:%d:%s" % [_run_seed_key, corridor_index, name])))
		_params[name] = values

## Corridor centre x at a world height (metres above the run start).
func corridor_x(corridor_index: int, world_height: float) -> float:
	return corridor_positions(world_height)[corridor_index]

## All corridor centres at a world height, left to right. Each drifts on its own seeded
## waves; neighbours are then pushed apart to MIN_CORRIDOR_GAP_METERS so two corridors
## never merge into one route.
func corridor_positions(world_height: float) -> PackedFloat32Array:
	var spacing: float = (_half_width * 2.0) / float(MAX_CORRIDORS)
	var xs: PackedFloat32Array = PackedFloat32Array()
	var _resize: int = xs.resize(MAX_CORRIDORS)
	for corridor_index in range(MAX_CORRIDORS):
		var base_x: float = -_half_width + spacing * (float(corridor_index) + 0.5)
		var drift: float = _params["a1"][corridor_index] * sin(TAU * world_height / _params["p1"][corridor_index] + _params["f1"][corridor_index])
		drift += _params["a2"][corridor_index] * sin(TAU * world_height / _params["p2"][corridor_index] + _params["f2"][corridor_index])
		var x: float = base_x + drift
		if world_height < OPENER_FAN_OUT_HEIGHT_METERS:
			var start_x: float = lerpf(-2.0, 2.0, float(corridor_index) / float(MAX_CORRIDORS - 1))
			x = lerpf(start_x, x, smoothstep(0.5, OPENER_FAN_OUT_HEIGHT_METERS, world_height))
		xs[corridor_index] = clampf(x, -_half_width, _half_width)
	if world_height >= OPENER_FAN_OUT_HEIGHT_METERS:
		for corridor_index in range(1, MAX_CORRIDORS):
			xs[corridor_index] = maxf(xs[corridor_index], xs[corridor_index - 1] + MIN_CORRIDOR_GAP_METERS)
		xs[MAX_CORRIDORS - 1] = minf(xs[MAX_CORRIDORS - 1], _half_width)
		for corridor_index in range(MAX_CORRIDORS - 2, -1, -1):
			xs[corridor_index] = minf(xs[corridor_index], xs[corridor_index + 1] - MIN_CORRIDOR_GAP_METERS)
	return xs

## Corridor strength in [0, 1] at a world height. 0 means the corridor is broken there.
## The wall is split into FADE_SEGMENT_METERS stretches; in each, one seeded corridor
## fades out for a few metres (forcing a traverse) while the others only vary in
## density, so at most one corridor is ever broken at a given height.
func corridor_strength(corridor_index: int, active_corridor_count: int, world_height: float) -> float:
	if corridor_index >= active_corridor_count:
		return 0.0
	if world_height < OPENER_FAN_OUT_HEIGHT_METERS:
		return 1.0
	var density: float = 0.8 + 0.2 * sin(TAU * world_height / _params["p3"][corridor_index] + _params["f3"][corridor_index])
	var segment: int = floori(world_height / FADE_SEGMENT_METERS)
	var faded_corridor: int = DeterministicHash.of_string("%s:fade:%d" % [_run_seed_key, segment]) % active_corridor_count
	if corridor_index != faded_corridor:
		return density
	var fade_centre: float = float(segment) * FADE_SEGMENT_METERS + lerpf(8.0, FADE_SEGMENT_METERS - 8.0, DeterministicHash.unit_float("%s:fade_at:%d" % [_run_seed_key, segment]))
	var fade_half_length: float = lerpf(3.0, 6.0, DeterministicHash.unit_float("%s:fade_len:%d" % [_run_seed_key, segment]))
	var distance: float = absf(world_height - fade_centre)
	return density * smoothstep(fade_half_length, fade_half_length + 1.5, distance)

## Samples hold positions for one chunk. fixed_points (previous chunk's seam band, or
## the opener's starter holds) are respected for spacing but not returned. Returns
## chunk-local positions (y negative up) in placement order.
func sample(
	profile: BandFieldProfileScript,
	chunk_start_height: float,
	segment_height: float,
	min_hold_height: float,
	fixed_points: PackedVector2Array,
	rng: RandomNumberGenerator,
	hold_budget: int
) -> PackedVector2Array:
	var spacing: float = profile.corridor_hold_spacing_meters
	var grid: Dictionary[Vector2i, PackedVector2Array] = {}
	for point in fixed_points:
		_grid_insert(grid, point, spacing)

	var placed: PackedVector2Array = PackedVector2Array()
	var top: float = -segment_height + 0.15
	var bottom: float = -min_hold_height
	# Sweep up each corridor in half-spacing steps with a few darts per step, instead of
	# throwing darts at the whole chunk: same blue-noise result, far fewer rejections.
	var step: float = spacing * 0.5
	var y: float = bottom
	while y >= top:
		var world_height: float = chunk_start_height - y
		for corridor_index in range(profile.corridor_count):
			var strength: float = corridor_strength(corridor_index, profile.corridor_count, world_height)
			if strength <= 0.0:
				continue
			var half_width: float = profile.corridor_half_width_meters * (0.6 + 0.4 * strength)
			var centre_x: float = corridor_x(corridor_index, world_height)
			for _dart in range(CORRIDOR_DARTS_PER_STEP):
				if placed.size() >= hold_budget or rng.randf() > strength:
					continue
				var candidate: Vector2 = Vector2(
					clampf(centre_x + rng.randf_range(-half_width, half_width), -_half_width, _half_width),
					clampf(y + rng.randf_range(-step * 0.5, step * 0.5), top, bottom)
				)
				if _is_clear(grid, candidate, spacing, spacing):
					_grid_insert(grid, candidate, spacing)
					var _a: bool = placed.append(candidate)
		y -= step

	var scatter_spacing: float = profile.scatter_hold_spacing_meters
	for _dart in range(SCATTER_DART_COUNT):
		if placed.size() >= hold_budget:
			break
		var candidate: Vector2 = Vector2(rng.randf_range(-_half_width, _half_width), rng.randf_range(top, bottom))
		if _is_clear(grid, candidate, scatter_spacing, spacing):
			_grid_insert(grid, candidate, spacing)
			var _a: bool = placed.append(candidate)
	return placed

func _is_clear(grid: Dictionary[Vector2i, PackedVector2Array], candidate: Vector2, min_distance: float, cell_size: float) -> bool:
	var reach: int = ceili(min_distance / cell_size)
	var cell: Vector2i = _cell_of(candidate, cell_size)
	for dx in range(-reach, reach + 1):
		for dy in range(-reach, reach + 1):
			var key: Vector2i = cell + Vector2i(dx, dy)
			if not grid.has(key):
				continue
			for other in grid[key]:
				if other.distance_to(candidate) < min_distance:
					return false
	return true

func _grid_insert(grid: Dictionary[Vector2i, PackedVector2Array], point: Vector2, cell_size: float) -> void:
	var cell: Vector2i = _cell_of(point, cell_size)
	# Packed arrays are copied out of a Dictionary, so append to a local and store it back.
	var bucket: PackedVector2Array = grid.get(cell, PackedVector2Array())
	var _a: bool = bucket.append(point)
	grid[cell] = bucket

func _cell_of(point: Vector2, cell_size: float) -> Vector2i:
	return Vector2i(floori(point.x / cell_size), floori(point.y / cell_size))
