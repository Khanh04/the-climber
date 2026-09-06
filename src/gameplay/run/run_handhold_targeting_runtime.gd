class_name RunHandholdTargetingRuntime
extends RefCounted

const GeneratedHandholdAdapterScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

func find_nearest_handhold(
	anchor_position: Vector2,
	handholds: Array,
	handhold_detection_radius_pixels: float,
	starter_handholds_root: Node,
	generation_tuning: Resource,
	aim_vector: Vector2 = Vector2.ZERO
) -> HandholdTargetScript:
	var typed_generation_tuning: GenerationTuningScript = _require_generation_tuning(generation_tuning)
	Validation.require_condition(handhold_detection_radius_pixels > 0.0, "RunHandholdTargetingRuntime detection radius must be positive.")
	Validation.require_condition(starter_handholds_root != null, "RunHandholdTargetingRuntime requires starter handholds root.")

	var aim_direction: Vector2 = Vector2.ZERO
	if aim_vector != Vector2.ZERO:
		aim_direction = aim_vector.normalized()

	var nearest_target: HandholdTargetScript = null
	var best_score: float = INF

	for handhold in handholds:
		Validation.require_condition(handhold is Node2D, "RunHandholdTargetingRuntime handholds must be Node2D instances.")
		var handhold_node: Node2D = handhold
		var distance: float = anchor_position.distance_to(handhold_node.global_position)
		if distance > handhold_detection_radius_pixels:
			continue

		# Bias toward the hold the player is aiming at so an overshoot no longer
		# snaps to a hold below the hand. Misaligned holds cost up to 10x their
		# distance but are never fully excluded -- a grab in range always resolves.
		var score: float = distance
		if aim_direction != Vector2.ZERO and distance > 0.0:
			var hold_direction: Vector2 = (handhold_node.global_position - anchor_position) / distance
			var alignment: float = clampf(0.5 + 0.5 * aim_direction.dot(hold_direction), 0.1, 1.0)
			score = distance / alignment

		if score <= best_score:
			nearest_target = HandholdTargetScript.new(
				StringName(handhold_node.name),
				handhold_node.global_position,
				handhold_node.get_path(),
				_require_handhold_drain_multiplier(handhold_node, starter_handholds_root, typed_generation_tuning),
				_require_handhold_type(handhold_node, starter_handholds_root)
			)
			best_score = score

	return nearest_target

func require_handhold_drain_multiplier(
	handhold_node: Node2D,
	starter_handholds_root: Node,
	generation_tuning: Resource
) -> float:
	return _require_handhold_drain_multiplier(
		handhold_node,
		starter_handholds_root,
		_require_generation_tuning(generation_tuning)
	)

func require_handhold_type(handhold_node: Node2D, starter_handholds_root: Node) -> int:
	return _require_handhold_type(handhold_node, starter_handholds_root)

func _require_handhold_drain_multiplier(
	handhold_node: Node2D,
	starter_handholds_root: Node,
	generation_tuning: GenerationTuningScript
) -> float:
	Validation.require_condition(handhold_node != null, "RunHandholdTargetingRuntime requires a handhold node when reading drain multiplier.")

	if handhold_node is GeneratedHandholdAdapterScript:
		var typed_handhold: GeneratedHandholdAdapterScript = handhold_node as GeneratedHandholdAdapterScript
		return typed_handhold.stamina_drain_multiplier

	if _is_authored_starter_handhold(handhold_node, starter_handholds_root):
		var normal_definition: HandholdTypeDefinitionScript = generation_tuning.get_required_handhold_definition(HandholdTypeScript.Value.NORMAL)
		Validation.require_condition(
			normal_definition.surface_profile is HandholdSurfaceProfileScript,
			"RunHandholdTargetingRuntime normal handhold definition requires a typed surface profile."
		)
		var normal_surface_profile: HandholdSurfaceProfileScript = normal_definition.surface_profile as HandholdSurfaceProfileScript
		return normal_surface_profile.stamina_drain_multiplier

	Validation.require_condition(handhold_node.has_meta(&"stamina_drain_multiplier"), "RunHandholdTargetingRuntime handholds must provide a stamina drain multiplier.")
	var raw_drain_multiplier: Variant = handhold_node.get_meta(&"stamina_drain_multiplier")
	Validation.require_condition(
		raw_drain_multiplier is float or raw_drain_multiplier is int,
		"RunHandholdTargetingRuntime handhold stamina drain multiplier metadata must be numeric."
	)
	var drain_multiplier: float = 0.0
	if raw_drain_multiplier is float:
		drain_multiplier = raw_drain_multiplier
	else:
		var typed_drain_multiplier_int: int = raw_drain_multiplier
		drain_multiplier = float(typed_drain_multiplier_int)
	Validation.require_condition(drain_multiplier > 0.0, "RunHandholdTargetingRuntime handhold stamina drain multiplier must be positive.")
	return drain_multiplier

func _require_handhold_type(handhold_node: Node2D, starter_handholds_root: Node) -> int:
	Validation.require_condition(handhold_node != null, "RunHandholdTargetingRuntime requires a handhold node when reading handhold type.")

	if handhold_node is GeneratedHandholdAdapterScript:
		var typed_handhold: GeneratedHandholdAdapterScript = handhold_node as GeneratedHandholdAdapterScript
		return typed_handhold.handhold_type

	if _is_authored_starter_handhold(handhold_node, starter_handholds_root):
		return HandholdTypeScript.Value.NORMAL

	Validation.require_condition(handhold_node.has_meta(&"handhold_type"), "RunHandholdTargetingRuntime handholds must provide a handhold type.")
	var raw_handhold_type: Variant = handhold_node.get_meta(&"handhold_type")
	Validation.require_condition(raw_handhold_type is String, "RunHandholdTargetingRuntime handhold type metadata must be a string label.")
	var handhold_type_label: String = raw_handhold_type
	var handhold_type: int = HandholdTypeScript.from_label(handhold_type_label)
	HandholdTypeScript.assert_valid(handhold_type)
	return handhold_type

func _is_authored_starter_handhold(handhold_node: Node2D, starter_handholds_root: Node) -> bool:
	Validation.require_condition(handhold_node != null, "RunHandholdTargetingRuntime requires a handhold node when checking starter-handhold ownership.")
	Validation.require_condition(starter_handholds_root != null, "RunHandholdTargetingRuntime requires starter handholds root when checking starter-handhold ownership.")
	return handhold_node is StaticBody2D \
		and not handhold_node is GeneratedHandholdAdapterScript \
		and handhold_node.get_parent() == starter_handholds_root

func _require_generation_tuning(generation_tuning: Resource) -> GenerationTuningScript:
	Validation.require_condition(generation_tuning != null, "RunHandholdTargetingRuntime requires generation tuning.")
	Validation.require_condition(generation_tuning is GenerationTuningScript, "RunHandholdTargetingRuntime requires GenerationTuning.")
	var typed_generation_tuning: GenerationTuningScript = generation_tuning as GenerationTuningScript
	typed_generation_tuning.assert_valid()
	return typed_generation_tuning
