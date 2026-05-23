class_name CosmeticLoadoutService
extends RefCounted

const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticItemScript = preload("res://resources/config/cosmetic_item.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")

func equip_item(loadout: Resource, inventory: RefCounted, catalog: Resource, item_id: StringName) -> void:
	var typed_loadout: CosmeticLoadoutScript = _require_loadout(loadout)
	var typed_inventory: CosmeticInventoryScript = _require_inventory(inventory)
	var typed_catalog: CosmeticItemCatalogScript = _require_catalog(catalog)
	var item: CosmeticItemScript = typed_catalog.get_required_item_by_id(item_id)
	Validation.require_condition(typed_inventory.is_owned(item.item_id), "CosmeticLoadoutService cannot equip an unowned cosmetic item.")

	match item.slot:
		CosmeticSlotScript.Value.BODY:
			typed_loadout.body_cosmetic_id = item.item_id
		CosmeticSlotScript.Value.LEFT_HAND:
			typed_loadout.left_hand_cosmetic_id = item.item_id
		CosmeticSlotScript.Value.RIGHT_HAND:
			typed_loadout.right_hand_cosmetic_id = item.item_id
		CosmeticSlotScript.Value.CHASER_THEME:
			typed_loadout.chaser_theme_id = item.chaser_theme_id
		CosmeticSlotScript.Value.PLAYER_APPEARANCE:
			typed_loadout.player_appearance_id = item.player_appearance_id
		_:
			Validation.require_condition(false, "CosmeticLoadoutService requires a supported cosmetic slot.")

	typed_loadout.assert_valid()
	assert_loadout_matches_catalog(typed_loadout, typed_catalog)
	assert_loadout_owned(typed_loadout, typed_inventory, typed_catalog)

func assert_loadout_matches_catalog(loadout: Resource, catalog: Resource) -> void:
	var typed_loadout: CosmeticLoadoutScript = _require_loadout(loadout)
	var typed_catalog: CosmeticItemCatalogScript = _require_catalog(catalog)
	typed_loadout.assert_valid()
	_assert_item_slot(typed_catalog.get_required_player_appearance_item_by_id(typed_loadout.player_appearance_id), CosmeticSlotScript.Value.PLAYER_APPEARANCE)
	_assert_item_slot(typed_catalog.get_required_item_by_id(typed_loadout.body_cosmetic_id), CosmeticSlotScript.Value.BODY)
	_assert_item_slot(typed_catalog.get_required_item_by_id(typed_loadout.left_hand_cosmetic_id), CosmeticSlotScript.Value.LEFT_HAND)
	_assert_item_slot(typed_catalog.get_required_item_by_id(typed_loadout.right_hand_cosmetic_id), CosmeticSlotScript.Value.RIGHT_HAND)
	_assert_item_slot(typed_catalog.get_required_chaser_item_by_theme_id(typed_loadout.chaser_theme_id), CosmeticSlotScript.Value.CHASER_THEME)

func assert_loadout_owned(loadout: Resource, inventory: RefCounted, catalog: Resource) -> void:
	var typed_loadout: CosmeticLoadoutScript = _require_loadout(loadout)
	var typed_inventory: CosmeticInventoryScript = _require_inventory(inventory)
	var typed_catalog: CosmeticItemCatalogScript = _require_catalog(catalog)
	assert_loadout_matches_catalog(typed_loadout, typed_catalog)
	var chaser_item: CosmeticItemScript = typed_catalog.get_required_chaser_item_by_theme_id(typed_loadout.chaser_theme_id)
	var player_appearance_item: CosmeticItemScript = typed_catalog.get_required_player_appearance_item_by_id(typed_loadout.player_appearance_id)
	Validation.require_condition(typed_inventory.is_owned(player_appearance_item.item_id), "Cosmetic loadout player appearance item must be owned.")
	Validation.require_condition(typed_inventory.is_owned(typed_loadout.body_cosmetic_id), "Cosmetic loadout body item must be owned.")
	Validation.require_condition(typed_inventory.is_owned(typed_loadout.left_hand_cosmetic_id), "Cosmetic loadout left-hand item must be owned.")
	Validation.require_condition(typed_inventory.is_owned(typed_loadout.right_hand_cosmetic_id), "Cosmetic loadout right-hand item must be owned.")
	Validation.require_condition(typed_inventory.is_owned(chaser_item.item_id), "Cosmetic loadout Chaser theme item must be owned.")

func is_item_equipped(loadout: Resource, item: Resource) -> bool:
	var typed_loadout: CosmeticLoadoutScript = _require_loadout(loadout)
	Validation.require_condition(item != null, "CosmeticLoadoutService requires an item to check equip state.")
	Validation.require_condition(item is CosmeticItemScript, "CosmeticLoadoutService requires a CosmeticItem to check equip state.")
	var typed_item: CosmeticItemScript = item as CosmeticItemScript
	typed_item.assert_valid()

	match typed_item.slot:
		CosmeticSlotScript.Value.PLAYER_APPEARANCE:
			return typed_loadout.player_appearance_id == typed_item.player_appearance_id
		CosmeticSlotScript.Value.BODY:
			return typed_loadout.body_cosmetic_id == typed_item.item_id
		CosmeticSlotScript.Value.LEFT_HAND:
			return typed_loadout.left_hand_cosmetic_id == typed_item.item_id
		CosmeticSlotScript.Value.RIGHT_HAND:
			return typed_loadout.right_hand_cosmetic_id == typed_item.item_id
		CosmeticSlotScript.Value.CHASER_THEME:
			return typed_loadout.chaser_theme_id == typed_item.chaser_theme_id
		_:
			Validation.require_condition(false, "CosmeticLoadoutService requires a supported cosmetic slot.")
			return false

func _require_loadout(loadout: Resource) -> CosmeticLoadoutScript:
	Validation.require_condition(loadout != null, "CosmeticLoadoutService requires a cosmetic loadout.")
	Validation.require_condition(loadout is CosmeticLoadoutScript, "CosmeticLoadoutService requires a CosmeticLoadout resource.")
	return loadout as CosmeticLoadoutScript

func _require_inventory(inventory: RefCounted) -> CosmeticInventoryScript:
	Validation.require_condition(inventory != null, "CosmeticLoadoutService requires a cosmetic inventory.")
	Validation.require_condition(inventory is CosmeticInventoryScript, "CosmeticLoadoutService requires a CosmeticInventory implementation.")
	return inventory as CosmeticInventoryScript

func _require_catalog(catalog: Resource) -> CosmeticItemCatalogScript:
	Validation.require_condition(catalog != null, "CosmeticLoadoutService requires a cosmetic item catalog.")
	Validation.require_condition(catalog is CosmeticItemCatalogScript, "CosmeticLoadoutService requires a CosmeticItemCatalog resource.")
	var typed_catalog: CosmeticItemCatalogScript = catalog as CosmeticItemCatalogScript
	typed_catalog.assert_valid()
	return typed_catalog

func _assert_item_slot(item: CosmeticItemScript, expected_slot: int) -> void:
	CosmeticSlotScript.assert_valid(expected_slot)
	Validation.require_condition(item != null, "CosmeticLoadoutService requires an item before checking its slot.")
	item.assert_valid()
	Validation.require_condition(item.slot == expected_slot, "CosmeticLoadoutService loadout item has the wrong cosmetic slot.")