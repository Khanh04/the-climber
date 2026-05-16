class_name HandholdTypeDefinition
extends Resource

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandholdLifecycleRuleScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")

@export var definition_id: StringName = &"NORMAL"
@export var handhold_type: int = HandholdTypeScript.Value.NORMAL
@export var display_name: String = "Normal"
@export var physical_size_meters: Vector2 = Vector2(1.12, 0.30)
@export var visual_color: Color = Color(0.92, 0.72, 0.23, 1.0)
@export var surface_profile: Resource = HandholdSurfaceProfileScript.new()
@export var lifecycle_rule: Resource = HandholdLifecycleRuleScript.new()
@export var movement_rule: Resource = HandholdMovementRuleScript.new()

func is_valid() -> bool:
	if String(definition_id).is_empty():
		return false

	if display_name.is_empty():
		return false

	if not HandholdTypeScript.is_valid(handhold_type):
		return false

	if physical_size_meters.x <= 0.0 or physical_size_meters.y <= 0.0:
		return false

	if surface_profile == null or not surface_profile is HandholdSurfaceProfileScript:
		return false

	if lifecycle_rule == null or not lifecycle_rule is HandholdLifecycleRuleScript:
		return false

	if movement_rule == null or not movement_rule is HandholdMovementRuleScript:
		return false

	var typed_surface_profile: HandholdSurfaceProfileScript = surface_profile as HandholdSurfaceProfileScript
	var typed_lifecycle_rule: HandholdLifecycleRuleScript = lifecycle_rule as HandholdLifecycleRuleScript
	var typed_movement_rule: HandholdMovementRuleScript = movement_rule as HandholdMovementRuleScript
	return typed_surface_profile.is_valid() and typed_lifecycle_rule.is_valid() and typed_movement_rule.is_valid()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not String(definition_id).is_empty(), "Handhold type definition requires a definition id.")
	Validation.require_condition(not display_name.is_empty(), "Handhold type definition requires a display name.")
	HandholdTypeScript.assert_valid(handhold_type)
	Validation.require_condition(
		physical_size_meters.x > 0.0 and physical_size_meters.y > 0.0,
		"Handhold type definition physical size must be positive."
	)
	Validation.require_condition(surface_profile != null, "Handhold type definition requires a surface profile.")
	Validation.require_condition(surface_profile is HandholdSurfaceProfileScript, "Handhold type definition surface profile must be typed.")
	Validation.require_condition(lifecycle_rule != null, "Handhold type definition requires a lifecycle rule.")
	Validation.require_condition(lifecycle_rule is HandholdLifecycleRuleScript, "Handhold type definition lifecycle rule must be typed.")
	Validation.require_condition(movement_rule != null, "Handhold type definition requires a movement rule.")
	Validation.require_condition(movement_rule is HandholdMovementRuleScript, "Handhold type definition movement rule must be typed.")

	var typed_surface_profile: HandholdSurfaceProfileScript = surface_profile as HandholdSurfaceProfileScript
	var typed_lifecycle_rule: HandholdLifecycleRuleScript = lifecycle_rule as HandholdLifecycleRuleScript
	var typed_movement_rule: HandholdMovementRuleScript = movement_rule as HandholdMovementRuleScript
	typed_surface_profile.assert_valid()
	typed_lifecycle_rule.assert_valid()
	typed_movement_rule.assert_valid()