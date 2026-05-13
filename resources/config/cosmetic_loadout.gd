class_name CosmeticLoadout
extends Resource

@export var chaser_theme_id: StringName = &"rising_void"

func is_valid() -> bool:
	return not chaser_theme_id.is_empty()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not chaser_theme_id.is_empty(), "Cosmetic loadout requires a chaser theme id.")