class_name HandholdMovementRule
extends Resource

@export var release_impulse_vector: Vector2 = Vector2.ZERO

func is_valid() -> bool:
	return true

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	pass