class_name HandholdTarget
extends RefCounted

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

var hold_id: StringName
var attach_position: Vector2
var hold_path: NodePath
var stamina_drain_multiplier: float
var handhold_type: int

func _init(
	hold_id_value: StringName,
	attach_position_value: Vector2,
	hold_path_value: NodePath = NodePath(),
	stamina_drain_multiplier_value: float = 1.0,
	handhold_type_value: int = HandholdTypeScript.Value.NORMAL
) -> void:
    hold_id = hold_id_value
    attach_position = attach_position_value
    hold_path = hold_path_value
    stamina_drain_multiplier = stamina_drain_multiplier_value
    handhold_type = handhold_type_value
    assert_valid()

func is_valid() -> bool:
    return not String(hold_id).is_empty() \
        and not hold_path.is_empty() \
        and stamina_drain_multiplier > 0.0 \
        and HandholdTypeScript.is_valid(handhold_type)

func assert_valid() -> void:
    Validation.require_condition(not String(hold_id).is_empty(), "Handhold target requires a hold id.")
    Validation.require_condition(not hold_path.is_empty(), "Handhold target requires a hold node path.")
    Validation.require_condition(stamina_drain_multiplier > 0.0, "Handhold target stamina drain multiplier must be positive.")
    HandholdTypeScript.assert_valid(handhold_type)
