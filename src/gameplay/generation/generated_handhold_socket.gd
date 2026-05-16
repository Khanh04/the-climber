class_name GeneratedHandholdSocket
extends RefCounted

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

var hold_id: StringName
var definition_id: StringName
var local_position: Vector2
var handhold_type: int
var physical_size_meters: Vector2
var stamina_drain_multiplier: float

func _init(
	hold_id_value: StringName,
	local_position_value: Vector2,
	stamina_drain_multiplier_value: float = -1.0,
	handhold_type_value: int = HandholdTypeScript.Value.NORMAL,
	definition_id_value: StringName = StringName(),
	physical_size_meters_value: Vector2 = Vector2.ZERO
) -> void:
    hold_id = hold_id_value
    local_position = local_position_value
    handhold_type = handhold_type_value
    HandholdTypeScript.assert_valid(handhold_type)
    if String(definition_id_value).is_empty():
        definition_id = HandholdTypeScript.get_default_definition_id(handhold_type)
    else:
        definition_id = definition_id_value

    if stamina_drain_multiplier_value > 0.0:
        stamina_drain_multiplier = stamina_drain_multiplier_value
    else:
        stamina_drain_multiplier = HandholdTypeScript.get_default_stamina_drain_multiplier(handhold_type)

    if physical_size_meters_value == Vector2.ZERO:
        physical_size_meters = HandholdTypeScript.get_default_physical_size_meters(handhold_type)
    else:
        physical_size_meters = physical_size_meters_value

    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(not String(hold_id).is_empty(), "GeneratedHandholdSocket requires a hold id.")
    Validation.require_condition(not String(definition_id).is_empty(), "GeneratedHandholdSocket requires a definition id.")
    HandholdTypeScript.assert_valid(handhold_type)
    Validation.require_condition(
        physical_size_meters.x > 0.0 and physical_size_meters.y > 0.0,
        "GeneratedHandholdSocket physical size must be positive."
    )
    Validation.require_condition(stamina_drain_multiplier > 0.0, "GeneratedHandholdSocket stamina drain multiplier must be positive.")