class_name ClimbPrototypeFrameResult
extends RefCounted

var control_force: Vector2
var stamina_depleted_now: bool
var attached_hand_count: int

func _init(control_force_value: Vector2, stamina_depleted_now_value: bool, attached_hand_count_value: int) -> void:
    control_force = control_force_value
    stamina_depleted_now = stamina_depleted_now_value
    attached_hand_count = attached_hand_count_value
    assert_valid()

func is_valid() -> bool:
    return attached_hand_count >= 0 and attached_hand_count <= 2

func assert_valid() -> void:
    Validation.require_condition(attached_hand_count >= 0 and attached_hand_count <= 2, "Climb prototype frame result attached hand count must be between 0 and 2.")
