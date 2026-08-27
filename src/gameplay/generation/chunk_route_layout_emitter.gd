class_name ChunkRouteLayoutEmitter
extends RefCounted

const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRoutePopulationScript: GDScript = preload("res://src/gameplay/generation/chunk_route_population.gd")
const ChunkTypeScript = preload("res://src/gameplay/generation/chunk_type.gd")
const GeneratedChunkLayoutScript: GDScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedHandholdSocketScript: GDScript = preload("res://src/gameplay/generation/generated_handhold_socket.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSocketScript: GDScript = preload("res://src/gameplay/generation/generated_hazard_socket.gd")
const GeneratedPickupSocketScript: GDScript = preload("res://src/gameplay/generation/generated_pickup_socket.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdLifecycleRuleScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteMovementStyleScript = preload("res://src/gameplay/generation/route_movement_style.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

var _tuning: GenerationTuningScript

func _init(tuning_value: GenerationTuningScript) -> void:
	Validation.require_condition(tuning_value != null, "ChunkRouteLayoutEmitter requires generation tuning.")
	_tuning = tuning_value
	_tuning.assert_valid()

func emit_layout(
	seed_key: String,
	plan: ChunkRoutePlanScript,
	population: RefCounted,
	route_validation_result: RefCounted = null,
	selected_candidate_attempt_index: int = 0,
	candidate_score: float = 0.0
) -> RefCounted:
	Validation.require_condition(seed_key != "", "ChunkRouteLayoutEmitter requires a seed key.")
	Validation.require_condition(
		seed_key.begins_with(_tuning.generator_version + ":"),
		"ChunkRouteLayoutEmitter seed key must match the configured generator version."
	)
	Validation.require_condition(plan != null, "ChunkRouteLayoutEmitter requires a route plan.")
	Validation.require_condition(population != null, "ChunkRouteLayoutEmitter requires a route population.")
	Validation.require_condition(selected_candidate_attempt_index >= 0, "ChunkRouteLayoutEmitter candidate attempt index cannot be negative.")
	Validation.require_condition(not is_nan(candidate_score), "ChunkRouteLayoutEmitter candidate score cannot be NaN.")
	plan.assert_valid()
	_require_population(population)

	var handholds: Array[GeneratedHandholdSocket] = _build_handhold_sockets(population)
	var pickup_sockets: Array[GeneratedPickupSocket] = _build_pickup_sockets(plan.chunk_index, population)
	var hazard_sockets: Array[GeneratedHazardSocket] = _build_hazard_sockets(plan.chunk_index, population)
	var safe_path_hold_ids: PackedStringArray = _require_population_hold_ids(population, &"safe_hold_ids")
	var route_entry_hold_ids: PackedStringArray = PackedStringArray([safe_path_hold_ids[0]])
	var route_exit_hold_ids: PackedStringArray = PackedStringArray([safe_path_hold_ids[safe_path_hold_ids.size() - 1]])
	var chunk_type: int = map_movement_style_to_chunk_type(plan.movement_style)

	var layout_variant: Variant = GeneratedChunkLayoutScript.new(
		seed_key,
		_tuning.generator_version,
		plan.chunk_index,
		chunk_type,
		plan.route_slot,
		plan.difficulty_band,
		float(plan.chunk_index) * _tuning.segment_height_meters,
		handholds,
		pickup_sockets,
		hazard_sockets,
		route_entry_hold_ids,
		route_exit_hold_ids,
		route_validation_result,
		selected_candidate_attempt_index,
		candidate_score,
		safe_path_hold_ids
	)
	Validation.require_condition(layout_variant is RefCounted, "ChunkRouteLayoutEmitter must create RefCounted generated layouts.")
	var layout: RefCounted = layout_variant
	return layout

func _require_population_hold_ids(population: RefCounted, property_name: StringName) -> PackedStringArray:
	var raw_hold_ids: Variant = population.get(property_name)
	Validation.require_condition(raw_hold_ids is PackedStringArray, "ChunkRouteLayoutEmitter population hold ids must be PackedStringArray values.")
	var hold_ids: PackedStringArray = raw_hold_ids
	Validation.require_condition(not hold_ids.is_empty(), "ChunkRouteLayoutEmitter population hold ids cannot be empty.")
	return PackedStringArray(hold_ids)

func map_movement_style_to_chunk_type(movement_style: int) -> int:
	RouteMovementStyleScript.assert_valid(movement_style)
	match movement_style:
		RouteMovementStyleScript.Value.LADDER:
			return ChunkTypeScript.Value.LADDER
		RouteMovementStyleScript.Value.ZIGZAG:
			return ChunkTypeScript.Value.ZIGZAG
		RouteMovementStyleScript.Value.RECOVERY:
			return ChunkTypeScript.Value.DENSE_RECOVERY
		RouteMovementStyleScript.Value.FORK:
			return ChunkTypeScript.Value.FORK
		RouteMovementStyleScript.Value.TRAVERSE_BRANCH:
			return ChunkTypeScript.Value.WIDE_TRAVERSE
		RouteMovementStyleScript.Value.RISK_LANE:
			return ChunkTypeScript.Value.RISK_LANE
		RouteMovementStyleScript.Value.PRESSURE:
			return ChunkTypeScript.Value.SWING_GAP
		_:
			Validation.require_condition(false, "ChunkRouteLayoutEmitter requires a supported movement style.")
			return ChunkTypeScript.Value.LADDER

func _build_handhold_sockets(population: RefCounted) -> Array[GeneratedHandholdSocket]:
	var handholds: Array[GeneratedHandholdSocket] = []
	var populated_holds: Array[RefCounted] = _require_ref_counted_array_property(population, &"holds")
	for populated_hold in populated_holds:
		var handhold_type: int = _require_int_property(populated_hold, &"handhold_type")
		HandholdTypeScript.assert_valid(handhold_type)
		var definition: HandholdTypeDefinitionScript = _tuning.get_required_handhold_definition(handhold_type)
		var surface_profile: HandholdSurfaceProfileScript = definition.surface_profile as HandholdSurfaceProfileScript
		var lifecycle_rule: HandholdLifecycleRuleScript = definition.lifecycle_rule as HandholdLifecycleRuleScript
		var movement_rule: HandholdMovementRuleScript = definition.movement_rule as HandholdMovementRuleScript
		var socket_variant: Variant = GeneratedHandholdSocketScript.new(
			_require_string_name_property(populated_hold, &"hold_id"),
			definition.definition_id,
			_require_vector2_property(populated_hold, &"local_position"),
			handhold_type,
			surface_profile.stamina_drain_multiplier,
			definition.physical_size_meters,
			definition.visual_color,
			lifecycle_rule.break_after_attach_seconds,
			lifecycle_rule.breaks_on_release,
			movement_rule.release_impulse_vector,
			_require_int_property(populated_hold, &"route_role")
		)
		Validation.require_condition(socket_variant is GeneratedHandholdSocket, "ChunkRouteLayoutEmitter must create generated handhold sockets.")
		var socket: GeneratedHandholdSocket = socket_variant
		handholds.append(socket)

	Validation.require_condition(not handholds.is_empty(), "ChunkRouteLayoutEmitter must emit at least one handhold socket.")
	return handholds

func _build_pickup_sockets(chunk_index: int, population: RefCounted) -> Array[GeneratedPickupSocket]:
	var pickup_sockets: Array[GeneratedPickupSocket] = []
	var reward_placements: Array[RefCounted] = _require_ref_counted_array_property(population, &"reward_placements")
	for socket_index in range(reward_placements.size()):
		var reward_placement: RefCounted = reward_placements[socket_index]
		var socket_id: StringName = StringName("chunk_%02d_pickup_%02d" % [chunk_index, socket_index])
		var socket_variant: Variant = GeneratedPickupSocketScript.new(
			socket_id,
			_build_pickup_position(reward_placement)
		)
		Validation.require_condition(socket_variant is GeneratedPickupSocket, "ChunkRouteLayoutEmitter must create generated pickup sockets.")
		var socket: GeneratedPickupSocket = socket_variant
		pickup_sockets.append(socket)

	return pickup_sockets

func _build_hazard_sockets(chunk_index: int, population: RefCounted) -> Array[GeneratedHazardSocket]:
	var hazard_sockets: Array[GeneratedHazardSocket] = []
	var hazard_placements: Array[RefCounted] = _require_ref_counted_array_property(population, &"hazard_placements")
	for socket_index in range(hazard_placements.size()):
		var hazard_placement: RefCounted = hazard_placements[socket_index]
		var hazard_kind: int = _require_int_property(hazard_placement, &"hazard_kind")
		GeneratedHazardKindScript.assert_valid(hazard_kind)
		var socket_id: StringName = StringName("chunk_%02d_hazard_%02d" % [chunk_index, socket_index])
		var socket_variant: Variant = GeneratedHazardSocketScript.new(
			socket_id,
			hazard_kind,
			_build_hazard_position(hazard_placement)
		)
		Validation.require_condition(socket_variant is GeneratedHazardSocket, "ChunkRouteLayoutEmitter must create generated hazard sockets.")
		var socket: GeneratedHazardSocket = socket_variant
		hazard_sockets.append(socket)

	return hazard_sockets

func _build_route_role_hold_ids(handholds: Array[GeneratedHandholdSocket], route_role: int) -> PackedStringArray:
	RouteRoleScript.assert_valid(route_role)
	var hold_ids: PackedStringArray = PackedStringArray()
	for handhold in handholds:
		if handhold.route_role == route_role:
			var _append_result: bool = hold_ids.append(String(handhold.hold_id))

	Validation.require_condition(hold_ids.size() > 0, "ChunkRouteLayoutEmitter route ports cannot be empty.")
	return hold_ids

func _build_pickup_position(reward_placement: RefCounted) -> Vector2:
	var anchor_position: Vector2 = _require_vector2_property(reward_placement, &"local_position")
	return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 0.65)

func _build_hazard_position(hazard_placement: RefCounted) -> Vector2:
	var hazard_kind: int = _require_int_property(hazard_placement, &"hazard_kind")
	var anchor_position: Vector2 = _require_vector2_property(hazard_placement, &"local_position")
	match hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y + 0.5)
		GeneratedHazardKindScript.Value.WIND_GUST:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 0.65)
		GeneratedHazardKindScript.Value.DOWNDRAFT:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 0.85)
		GeneratedHazardKindScript.Value.UPDRAFT:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 1.05)
		GeneratedHazardKindScript.Value.FALLING_ROCK:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 0.6)
		GeneratedHazardKindScript.Value.PENDULUM_LOG:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 0.75)
		GeneratedHazardKindScript.Value.WANDERING_CRITTER:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y + 0.55)
		GeneratedHazardKindScript.Value.STARTLE_PUFF:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 0.55)
		GeneratedHazardKindScript.Value.BUG_SWARM:
			return Vector2(_clamp_local_x(anchor_position.x), anchor_position.y - 0.55)
		_:
			Validation.require_condition(false, "ChunkRouteLayoutEmitter requires a supported hazard kind.")
			return anchor_position

func _clamp_local_x(local_x: float) -> float:
	var half_width: float = _tuning.chunk_width_meters * 0.5
	return clampf(local_x, -half_width, half_width)

func _require_population(population: RefCounted) -> void:
	var uses_expected_script: bool = population.get_script() == ChunkRoutePopulationScript
	Validation.require_condition(uses_expected_script, "ChunkRouteLayoutEmitter requires a ChunkRoutePopulation instance.")
	Validation.require_condition(population.has_method("assert_valid"), "ChunkRouteLayoutEmitter population must expose assert_valid().")
	population.call("assert_valid")

func _require_ref_counted_array_property(source: RefCounted, property_name: StringName) -> Array[RefCounted]:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is Array, "ChunkRouteLayoutEmitter expected an Array property.")
	var raw_array: Array = raw_value
	var typed_values: Array[RefCounted] = []
	for value in raw_array:
		Validation.require_condition(value is RefCounted, "ChunkRouteLayoutEmitter expected RefCounted array values.")
		var typed_value: RefCounted = value
		typed_values.append(typed_value)
	return typed_values

func _require_string_name_property(source: RefCounted, property_name: StringName) -> StringName:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is StringName, "ChunkRouteLayoutEmitter expected a StringName property.")
	var typed_value: StringName = raw_value
	return typed_value

func _require_int_property(source: RefCounted, property_name: StringName) -> int:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is int, "ChunkRouteLayoutEmitter expected an int property.")
	var typed_value: int = raw_value
	return typed_value

func _require_vector2_property(source: RefCounted, property_name: StringName) -> Vector2:
	var raw_value: Variant = source.get(property_name)
	Validation.require_condition(raw_value is Vector2, "ChunkRouteLayoutEmitter expected a Vector2 property.")
	var typed_value: Vector2 = raw_value
	return typed_value
