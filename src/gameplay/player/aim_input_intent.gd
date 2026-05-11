class_name AimInputIntent
extends RefCounted

var aim_vector: Vector2

func _init(aim_vector_value: Vector2) -> void:
    aim_vector = aim_vector_value
    assert_valid()

func is_valid() -> bool:
    return aim_vector != Vector2.ZERO

func assert_valid() -> void:
    Validation.require_condition(aim_vector != Vector2.ZERO, "Aim input intent requires a non-zero aim vector.")