class_name CosmeticItemCatalog
extends Resource

const CosmeticItemScript = preload("res://resources/config/cosmetic_item.gd")
const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")

@export var items: Array[Resource] = []

func is_valid() -> bool:
	if items.is_empty():
		return false

	var seen_item_ids: Dictionary[StringName, bool] = {}
	var seen_chaser_theme_ids: Dictionary[StringName, bool] = {}
	var seen_player_appearance_ids: Dictionary[StringName, bool] = {}
	for item in items:
		if item == null or not item is CosmeticItemScript:
			return false

		var typed_item: CosmeticItemScript = item as CosmeticItemScript
		if not typed_item.is_valid() or seen_item_ids.has(typed_item.item_id):
			return false

		if typed_item.slot == CosmeticSlotScript.Value.CHASER_THEME:
			if seen_chaser_theme_ids.has(typed_item.chaser_theme_id):
				return false

			seen_chaser_theme_ids[typed_item.chaser_theme_id] = true
		elif typed_item.slot == CosmeticSlotScript.Value.PLAYER_APPEARANCE:
			if seen_player_appearance_ids.has(typed_item.player_appearance_id):
				return false

			seen_player_appearance_ids[typed_item.player_appearance_id] = true

		seen_item_ids[typed_item.item_id] = true

	return true

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not items.is_empty(), "Cosmetic item catalog requires at least one item.")

	var seen_item_ids: Dictionary[StringName, bool] = {}
	var seen_chaser_theme_ids: Dictionary[StringName, bool] = {}
	var seen_player_appearance_ids: Dictionary[StringName, bool] = {}
	for item in items:
		Validation.require_condition(item != null, "Cosmetic item catalog cannot contain null items.")
		Validation.require_condition(item is CosmeticItemScript, "Cosmetic item catalog requires CosmeticItem resources.")
		var typed_item: CosmeticItemScript = item as CosmeticItemScript
		typed_item.assert_valid()
		Validation.require_condition(not seen_item_ids.has(typed_item.item_id), "Cosmetic item catalog item ids must be unique.")
		if typed_item.slot == CosmeticSlotScript.Value.CHASER_THEME:
			Validation.require_condition(not seen_chaser_theme_ids.has(typed_item.chaser_theme_id), "Cosmetic item catalog Chaser theme ids must be unique.")
			seen_chaser_theme_ids[typed_item.chaser_theme_id] = true
		elif typed_item.slot == CosmeticSlotScript.Value.PLAYER_APPEARANCE:
			Validation.require_condition(
				not seen_player_appearance_ids.has(typed_item.player_appearance_id),
				"Cosmetic item catalog player appearance ids must be unique."
			)
			seen_player_appearance_ids[typed_item.player_appearance_id] = true

		seen_item_ids[typed_item.item_id] = true

func get_all_items() -> Array[CosmeticItemScript]:
	assert_valid()
	var typed_items: Array[CosmeticItemScript] = []
	for item in items:
		typed_items.append(item as CosmeticItemScript)
	return typed_items

func get_items_for_slot(slot_value: int) -> Array[CosmeticItemScript]:
	CosmeticSlotScript.assert_valid(slot_value)
	assert_valid()
	var slot_items: Array[CosmeticItemScript] = []
	for item in items:
		var typed_item: CosmeticItemScript = item as CosmeticItemScript
		if typed_item.slot == slot_value:
			slot_items.append(typed_item)
	return slot_items

func get_default_unlocked_item_ids() -> PackedStringArray:
	assert_valid()
	var default_item_ids: PackedStringArray = PackedStringArray()
	for item in items:
		var typed_item: CosmeticItemScript = item as CosmeticItemScript
		if typed_item.default_unlocked:
			var _append_result: bool = default_item_ids.append(String(typed_item.item_id))
	return default_item_ids

func get_required_item_by_id(item_id: StringName) -> CosmeticItemScript:
	Validation.require_condition(not item_id.is_empty(), "Cosmetic item catalog lookup requires an item id.")
	assert_valid()

	for item in items:
		var typed_item: CosmeticItemScript = item as CosmeticItemScript
		if typed_item.item_id == item_id:
			return typed_item

	Validation.require_condition(false, "Cosmetic item catalog is missing item id %s." % String(item_id))
	return null

func get_required_chaser_item_by_theme_id(chaser_theme_id: StringName) -> CosmeticItemScript:
	Validation.require_condition(not chaser_theme_id.is_empty(), "Cosmetic item catalog Chaser lookup requires a theme id.")
	assert_valid()

	for item in items:
		var typed_item: CosmeticItemScript = item as CosmeticItemScript
		if typed_item.slot == CosmeticSlotScript.Value.CHASER_THEME and typed_item.chaser_theme_id == chaser_theme_id:
			return typed_item

	Validation.require_condition(false, "Cosmetic item catalog is missing Chaser theme id %s." % String(chaser_theme_id))
	return null

func get_required_player_appearance_item_by_id(player_appearance_id: StringName) -> CosmeticItemScript:
	Validation.require_condition(not player_appearance_id.is_empty(), "Cosmetic item catalog player appearance lookup requires an appearance id.")
	assert_valid()

	for item in items:
		var typed_item: CosmeticItemScript = item as CosmeticItemScript
		if typed_item.slot == CosmeticSlotScript.Value.PLAYER_APPEARANCE and typed_item.player_appearance_id == player_appearance_id:
			return typed_item

	Validation.require_condition(false, "Cosmetic item catalog is missing player appearance id %s." % String(player_appearance_id))
	return null