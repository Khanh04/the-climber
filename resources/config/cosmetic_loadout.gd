class_name CosmeticLoadout
extends Resource

@export var player_appearance_id: StringName = &"human"
@export var chaser_theme_id: StringName = &"rising_void"
@export var body_cosmetic_id: StringName = &"body_default"
@export var left_hand_cosmetic_id: StringName = &"left_hand_default"
@export var right_hand_cosmetic_id: StringName = &"right_hand_default"

func is_valid() -> bool:
	return not player_appearance_id.is_empty() \
		and not chaser_theme_id.is_empty() \
		and not body_cosmetic_id.is_empty() \
		and not left_hand_cosmetic_id.is_empty() \
		and not right_hand_cosmetic_id.is_empty()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not player_appearance_id.is_empty(), "Cosmetic loadout requires a player appearance id.")
	Validation.require_condition(not chaser_theme_id.is_empty(), "Cosmetic loadout requires a chaser theme id.")
	Validation.require_condition(not body_cosmetic_id.is_empty(), "Cosmetic loadout requires a body cosmetic id.")
	Validation.require_condition(not left_hand_cosmetic_id.is_empty(), "Cosmetic loadout requires a left-hand cosmetic id.")
	Validation.require_condition(not right_hand_cosmetic_id.is_empty(), "Cosmetic loadout requires a right-hand cosmetic id.")