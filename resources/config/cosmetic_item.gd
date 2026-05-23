class_name CosmeticItem
extends Resource

const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")

@export var item_id: StringName = &"body_default"
@export var display_name: String = "Default Body"
@export var slot: int = CosmeticSlotScript.Value.BODY
@export var price_coins: int = 0
@export var default_unlocked: bool = false
@export var chaser_theme_id: StringName = StringName()
@export var player_appearance_id: StringName = StringName()
@export var visual_color: Color = Color(0.92, 0.94, 0.98, 1.0)
@export var accent_color: Color = Color(0.24, 0.36, 0.48, 1.0)

func is_valid() -> bool:
	if item_id.is_empty():
		return false

	if display_name.is_empty():
		return false

	if not CosmeticSlotScript.is_valid(slot):
		return false

	if price_coins < 0:
		return false

	if slot == CosmeticSlotScript.Value.CHASER_THEME:
		return not chaser_theme_id.is_empty() and player_appearance_id.is_empty()

	if slot == CosmeticSlotScript.Value.PLAYER_APPEARANCE:
		return chaser_theme_id.is_empty() and not player_appearance_id.is_empty()

	return chaser_theme_id.is_empty() and player_appearance_id.is_empty()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not item_id.is_empty(), "Cosmetic item id cannot be empty.")
	Validation.require_condition(not display_name.is_empty(), "Cosmetic item display name cannot be empty.")
	CosmeticSlotScript.assert_valid(slot)
	Validation.require_condition(price_coins >= 0, "Cosmetic item price cannot be negative.")

	if slot == CosmeticSlotScript.Value.CHASER_THEME:
		Validation.require_condition(not chaser_theme_id.is_empty(), "Chaser theme cosmetic item requires a chaser theme id.")
		Validation.require_condition(player_appearance_id.is_empty(), "Chaser theme cosmetic item cannot define a player appearance id.")
	elif slot == CosmeticSlotScript.Value.PLAYER_APPEARANCE:
		Validation.require_condition(chaser_theme_id.is_empty(), "Player appearance cosmetic item cannot define a chaser theme id.")
		Validation.require_condition(not player_appearance_id.is_empty(), "Player appearance cosmetic item requires a player appearance id.")
	else:
		Validation.require_condition(chaser_theme_id.is_empty(), "Player cosmetic items cannot define a chaser theme id.")
		Validation.require_condition(player_appearance_id.is_empty(), "Non-appearance cosmetic items cannot define a player appearance id.")