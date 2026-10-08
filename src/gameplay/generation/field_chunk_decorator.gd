class_name FieldChunkDecorator
extends RefCounted

## Assigns hold types and route roles, places coins and hazards on a validated hold field.
## Rules (docs/adr/0011-hold-field-generation.md):
## - The easiest route only uses the band's safe hold types.
## - A lethal hazard may only cover holds when the chunk still offers K-1 distinct routes
##   without them, never a route source, never a coin.
## - Force hazards land on the easiest route only some of the time; coins sit off it.

const BandFieldProfileScript = preload("res://resources/config/band_field_profile.gd")
const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

const HAZARD_MIN_SPACING_METERS: float = 1.5
const COIN_MIN_SPACING_METERS: float = 3.0
const COIN_OFFSET_ABOVE_HOLD: Vector2 = Vector2(0.0, -0.55)
const HAZARD_OFFSET_ABOVE_HOLD: Vector2 = Vector2(0.0, -0.6)
const LETHAL_PLACEMENT_TRIES: int = 24
## Share of non-lethal hazards that go on the easiest route; the rest go on other routes.
const EASIEST_ROUTE_HAZARD_SHARE: float = 0.4
## Margin added around a lethal hazard's motion envelope for the hand reaching a hold.
const ENVELOPE_HOLD_MARGIN_METERS: float = 0.2

var hold_types: PackedInt32Array
var hold_roles: PackedInt32Array
var coin_positions: PackedVector2Array
var hazard_kinds: PackedInt32Array
var hazard_positions: PackedVector2Array

## first_new_node: graph nodes below it are the previous chunk's seam holds (not emitted).
func decorate(
	graph: HoldReachGraph,
	first_new_node: int,
	routes: Array[PackedInt32Array],
	sources: PackedInt32Array,
	is_target: PackedByteArray,
	exempt: PackedByteArray,
	corridor_guides: Array[PackedByteArray],
	difficulty_band: int,
	is_opener: bool,
	profile: BandFieldProfileScript,
	hazard_count: int,
	max_route_move: float,
	route_separation: float,
	half_width: float,
	segment_height: float,
	rng: RandomNumberGenerator
) -> void:
	Validation.require_condition(not routes.is_empty(), "FieldChunkDecorator requires at least one route.")
	var node_total: int = graph.node_count()
	hold_types = PackedInt32Array()
	hold_roles = PackedInt32Array()
	var _t: int = hold_types.resize(node_total)
	var _r: int = hold_roles.resize(node_total)
	hold_types.fill(HandholdTypeScript.Value.NORMAL)
	hold_roles.fill(RouteRoleScript.Value.SETUP)

	var on_easiest: PackedByteArray = graph.empty_mask()
	for node in routes[0]:
		on_easiest[node] = 1
	var on_other_route: PackedByteArray = graph.empty_mask()
	for route_index in range(1, routes.size()):
		for node in routes[route_index]:
			if on_easiest[node] == 0:
				on_other_route[node] = 1
				hold_roles[node] = RouteRoleScript.Value.OPTIONAL_BETA

	_assign_easiest_route_types(graph, routes[0], first_new_node, difficulty_band, is_opener, rng)
	_assign_other_types(node_total, first_new_node, on_easiest, difficulty_band, is_opener, profile.special_hold_chance, rng)
	_place_coins(graph, first_new_node, on_easiest, on_other_route, routes[0], profile.coin_count, segment_height, rng)
	hazard_kinds = PackedInt32Array()
	hazard_positions = PackedVector2Array()
	for _hazard_index in range(hazard_count):
		if rng.randf() < profile.lethal_hazard_share:
			_place_lethal_hazard(graph, first_new_node, sources, is_target, exempt, corridor_guides, profile, max_route_move, route_separation, half_width, rng)
		else:
			_place_route_hazard(graph, first_new_node, routes, half_width, rng)

static func safe_types(difficulty_band: int, is_opener: bool) -> Array[int]:
	if is_opener:
		return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST]
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST]
		ChunkDifficultyBandScript.Value.BASELINE:
			return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST, HandholdTypeScript.Value.BURN]
		_:
			return [HandholdTypeScript.Value.NORMAL, HandholdTypeScript.Value.REST, HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.BREAK, HandholdTypeScript.Value.BOOST]

static func special_types(difficulty_band: int, is_opener: bool) -> Array[int]:
	if is_opener:
		return [HandholdTypeScript.Value.REST]
	match difficulty_band:
		ChunkDifficultyBandScript.Value.EASY:
			return [HandholdTypeScript.Value.REST, HandholdTypeScript.Value.BURN]
		ChunkDifficultyBandScript.Value.BASELINE:
			return [HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.BOOST, HandholdTypeScript.Value.ROCKET]
		_:
			return [HandholdTypeScript.Value.BURN, HandholdTypeScript.Value.BREAK, HandholdTypeScript.Value.BOOST, HandholdTypeScript.Value.GHOST, HandholdTypeScript.Value.ROCKET]

## Lethal hazard motion envelope relative to the hazard socket (y negative up), from the
## runtime constants in generated_hazard_spawn_adapter.gd.
static func lethal_envelope(hazard_kind: int) -> Rect2:
	match hazard_kind:
		GeneratedHazardKindScript.Value.FALLING_ROCK:
			return Rect2(-0.3, -0.2, 0.6, 2.2)
		GeneratedHazardKindScript.Value.PENDULUM_LOG:
			return Rect2(-0.7, -0.2, 1.4, 0.55)
		_:
			return Rect2(-0.45, -0.45, 0.9, 0.9)

func _assign_easiest_route_types(graph: HoldReachGraph, route: PackedInt32Array, first_new_node: int, difficulty_band: int, is_opener: bool, rng: RandomNumberGenerator) -> void:
	var allowed: Array[int] = safe_types(difficulty_band, is_opener)
	var crux_index: int = 1
	var longest: float = -1.0
	for index in range(1, route.size()):
		var length: float = graph.positions[route[index - 1]].distance_to(graph.positions[route[index]])
		if length > longest:
			longest = length
			crux_index = index
	var first_new_index: int = -1
	for index in range(route.size()):
		var node: int = route[index]
		if node < first_new_node:
			continue
		if first_new_index == -1:
			first_new_index = index
			hold_roles[node] = RouteRoleScript.Value.ENTRY
		else:
			hold_roles[node] = RouteRoleScript.Value.SETUP
		if index == crux_index:
			hold_roles[node] = RouteRoleScript.Value.CRUX
			if allowed.has(HandholdTypeScript.Value.BURN):
				hold_types[node] = HandholdTypeScript.Value.BURN
		elif index == crux_index - 1 and allowed.has(HandholdTypeScript.Value.BOOST) and rng.randf() < 0.4:
			hold_types[node] = HandholdTypeScript.Value.BOOST
		elif rng.randf() < 0.12:
			hold_types[node] = HandholdTypeScript.Value.REST
			hold_roles[node] = RouteRoleScript.Value.RECOVERY
	var last_node: int = route[route.size() - 1]
	if last_node >= first_new_node and hold_roles[last_node] != RouteRoleScript.Value.CRUX:
		hold_roles[last_node] = RouteRoleScript.Value.TOP_OUT

func _assign_other_types(node_total: int, first_new_node: int, on_easiest: PackedByteArray, difficulty_band: int, is_opener: bool, chance: float, rng: RandomNumberGenerator) -> void:
	var pool: Array[int] = special_types(difficulty_band, is_opener)
	for node in range(first_new_node, node_total):
		if on_easiest[node] == 1:
			continue
		if rng.randf() < chance:
			hold_types[node] = pool[rng.randi_range(0, pool.size() - 1)]
			if hold_types[node] == HandholdTypeScript.Value.REST and hold_roles[node] == RouteRoleScript.Value.SETUP:
				hold_roles[node] = RouteRoleScript.Value.RECOVERY

func _place_coins(graph: HoldReachGraph, first_new_node: int, on_easiest: PackedByteArray, on_other_route: PackedByteArray, easiest_route: PackedInt32Array, coin_count: int, segment_height: float, rng: RandomNumberGenerator) -> void:
	coin_positions = PackedVector2Array()
	var preferred: PackedInt32Array = PackedInt32Array()
	var fallback: PackedInt32Array = PackedInt32Array()
	for node in range(first_new_node, graph.node_count()):
		var point: Vector2 = graph.positions[node]
		if on_easiest[node] == 1 or point.y > -0.8 or point.y < -segment_height + 0.6:
			continue
		var away_from_easiest: bool = absf(point.x - graph.route_x_at(easiest_route, point.y)) >= 1.5
		if on_other_route[node] == 1 or away_from_easiest:
			var _p: bool = preferred.append(node)
		else:
			var _f: bool = fallback.append(node)
	for pool in [_shuffled(preferred, rng), _shuffled(fallback, rng)]:
		var typed_pool: PackedInt32Array = pool
		for node in typed_pool:
			if coin_positions.size() >= coin_count:
				return
			var coin: Vector2 = graph.positions[node] + COIN_OFFSET_ABOVE_HOLD
			if _far_from_all(coin, coin_positions, COIN_MIN_SPACING_METERS):
				var _c: bool = coin_positions.append(coin)
				hold_roles[node] = RouteRoleScript.Value.REWARD

func _place_lethal_hazard(
	graph: HoldReachGraph,
	first_new_node: int,
	sources: PackedInt32Array,
	is_target: PackedByteArray,
	exempt: PackedByteArray,
	corridor_guides: Array[PackedByteArray],
	profile: BandFieldProfileScript,
	max_route_move: float,
	route_separation: float,
	half_width: float,
	rng: RandomNumberGenerator
) -> void:
	var kind: int = _pick_weighted([GeneratedHazardKindScript.Value.SPIKE_CLUSTER, GeneratedHazardKindScript.Value.FALLING_ROCK, GeneratedHazardKindScript.Value.PENDULUM_LOG], [0.45, 0.35, 0.2], rng)
	var required_routes: int = maxi(1, profile.required_route_count - 1)
	for _try in range(LETHAL_PLACEMENT_TRIES):
		var anchor: int = rng.randi_range(first_new_node, graph.node_count() - 1)
		var position: Vector2 = graph.positions[anchor] + Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-1.0, -0.3))
		if absf(position.x) > half_width or not _far_from_all(position, hazard_positions, HAZARD_MIN_SPACING_METERS):
			continue
		var envelope: Rect2 = lethal_envelope(kind)
		envelope.position += position
		var reach_envelope: Rect2 = envelope.grow(ENVELOPE_HOLD_MARGIN_METERS)
		if _any_point_inside(coin_positions, reach_envelope):
			continue
		var banned: PackedByteArray = graph.empty_mask()
		var covers_source: bool = false
		for node in range(graph.node_count()):
			if reach_envelope.has_point(graph.positions[node]):
				banned[node] = 1
				covers_source = covers_source or sources.has(node)
		if covers_source:
			continue
		var surviving: Array[PackedInt32Array] = graph.distinct_routes(sources, is_target, exempt, max_route_move, route_separation, required_routes, banned, corridor_guides)
		if surviving.size() < required_routes:
			continue
		for node in range(first_new_node, graph.node_count()):
			if banned[node] == 1:
				hold_roles[node] = RouteRoleScript.Value.HAZARD_DENIAL
		var _k: bool = hazard_kinds.append(kind)
		var _p: bool = hazard_positions.append(position)
		return

func _place_route_hazard(graph: HoldReachGraph, first_new_node: int, routes: Array[PackedInt32Array], half_width: float, rng: RandomNumberGenerator) -> void:
	var kinds: Array[int] = [
		GeneratedHazardKindScript.Value.WIND_GUST,
		GeneratedHazardKindScript.Value.DOWNDRAFT,
		GeneratedHazardKindScript.Value.WANDERING_CRITTER,
		GeneratedHazardKindScript.Value.UPDRAFT,
		GeneratedHazardKindScript.Value.STARTLE_PUFF,
	]
	var weights: Array[float] = [0.25, 0.2, 0.15, 0.12, 0.13]
	if not coin_positions.is_empty():
		kinds.append(GeneratedHazardKindScript.Value.BUG_SWARM)
		weights.append(0.15)
	var kind: int = _pick_weighted(kinds, weights, rng)
	for _try in range(8):
		var position: Vector2
		if kind == GeneratedHazardKindScript.Value.BUG_SWARM:
			position = coin_positions[rng.randi_range(0, coin_positions.size() - 1)] + Vector2(rng.randf_range(-0.8, 0.8), 0.4)
		else:
			var route_index: int = 0
			if routes.size() > 1 and rng.randf() >= EASIEST_ROUTE_HAZARD_SHARE:
				route_index = rng.randi_range(1, routes.size() - 1)
			var route: PackedInt32Array = routes[route_index]
			var route_position: int = rng.randi_range(1, route.size() - 1)
			if kind == GeneratedHazardKindScript.Value.UPDRAFT:
				route_position = _longest_move_index(graph, route)
			var node: int = route[route_position]
			if node < first_new_node:
				continue
			position = graph.positions[node] + HAZARD_OFFSET_ABOVE_HOLD
			if kind == GeneratedHazardKindScript.Value.UPDRAFT:
				position = (graph.positions[route[route_position - 1]] + graph.positions[node]) * 0.5
		if absf(position.x) > half_width or not _far_from_all(position, hazard_positions, HAZARD_MIN_SPACING_METERS):
			continue
		var _k: bool = hazard_kinds.append(kind)
		var _p: bool = hazard_positions.append(position)
		return

func _longest_move_index(graph: HoldReachGraph, route: PackedInt32Array) -> int:
	var best_index: int = 1
	var longest: float = -1.0
	for index in range(1, route.size()):
		var length: float = graph.positions[route[index - 1]].distance_to(graph.positions[route[index]])
		if length > longest:
			longest = length
			best_index = index
	return best_index

func _pick_weighted(kinds: Array[int], weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for weight in weights:
		total += weight
	var roll: float = rng.randf() * total
	for index in range(kinds.size()):
		roll -= weights[index]
		if roll <= 0.0:
			return kinds[index]
	return kinds[kinds.size() - 1]

func _shuffled(values: PackedInt32Array, rng: RandomNumberGenerator) -> PackedInt32Array:
	var shuffled: PackedInt32Array = values.duplicate()
	for index in range(shuffled.size() - 1, 0, -1):
		var swap: int = rng.randi_range(0, index)
		var held: int = shuffled[index]
		shuffled[index] = shuffled[swap]
		shuffled[swap] = held
	return shuffled

func _far_from_all(point: Vector2, others: PackedVector2Array, min_distance: float) -> bool:
	for other in others:
		if other.distance_to(point) < min_distance:
			return false
	return true

func _any_point_inside(points: PackedVector2Array, area: Rect2) -> bool:
	for point in points:
		if area.has_point(point):
			return true
	return false
