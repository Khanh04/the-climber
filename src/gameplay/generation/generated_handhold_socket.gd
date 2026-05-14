class_name GeneratedHandholdSocket
extends RefCounted

var hold_id: StringName
var local_position: Vector2
var stamina_drain_multiplier: float

func _init(hold_id_value: StringName, local_position_value: Vector2, stamina_drain_multiplier_value: float = 1.0) -> void:
    hold_id = hold_id_value
    local_position = local_position_value
    stamina_drain_multiplier = stamina_drain_multiplier_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(not String(hold_id).is_empty(), "GeneratedHandholdSocket requires a hold id.")
    Validation.require_condition(stamina_drain_multiplier > 0.0, "GeneratedHandholdSocket stamina drain multiplier must be positive.")