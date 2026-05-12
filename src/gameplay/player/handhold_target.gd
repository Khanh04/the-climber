class_name HandholdTarget
extends RefCounted

var hold_id: StringName
var attach_position: Vector2
var hold_path: NodePath
var stamina_drain_multiplier: float

func _init(hold_id_value: StringName, attach_position_value: Vector2, hold_path_value: NodePath = NodePath(), stamina_drain_multiplier_value: float = 1.0) -> void:
    hold_id = hold_id_value
    attach_position = attach_position_value
    hold_path = hold_path_value
    stamina_drain_multiplier = stamina_drain_multiplier_value
    assert_valid()

func is_valid() -> bool:
    return not String(hold_id).is_empty() and not hold_path.is_empty() and stamina_drain_multiplier > 0.0

func assert_valid() -> void:
    Validation.require_condition(not String(hold_id).is_empty(), "Handhold target requires a hold id.")
    Validation.require_condition(not hold_path.is_empty(), "Handhold target requires a hold node path.")
    Validation.require_condition(stamina_drain_multiplier > 0.0, "Handhold target stamina drain multiplier must be positive.")
