class_name StoreItemState
extends RefCounted

const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")

var item_id: StringName
var display_name: String
var slot: int
var price_coins: int
var owned: bool
var equipped: bool
var can_purchase: bool
var can_equip: bool

func _init(
	item_id_value: StringName = &"body_default",
	display_name_value: String = "Default Body",
	slot_value: int = CosmeticSlotScript.Value.BODY,
	price_coins_value: int = 0,
	owned_value: bool = false,
	equipped_value: bool = false,
	can_purchase_value: bool = false,
	can_equip_value: bool = false
) -> void:
	item_id = item_id_value
	display_name = display_name_value
	slot = slot_value
	price_coins = price_coins_value
	owned = owned_value
	equipped = equipped_value
	can_purchase = can_purchase_value
	can_equip = can_equip_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not item_id.is_empty(), "StoreItemState item id cannot be empty.")
	Validation.require_condition(not display_name.is_empty(), "StoreItemState display name cannot be empty.")
	CosmeticSlotScript.assert_valid(slot)
	Validation.require_condition(price_coins >= 0, "StoreItemState price cannot be negative.")
	Validation.require_condition(not equipped or owned, "StoreItemState equipped items must be owned.")
	Validation.require_condition(not can_purchase or not owned, "StoreItemState owned items cannot be purchasable.")
	Validation.require_condition(not can_purchase or price_coins > 0, "StoreItemState purchasable items require a positive price.")
	Validation.require_condition(not can_equip or owned, "StoreItemState equip-enabled items must be owned.")
	Validation.require_condition(not can_equip or not equipped, "StoreItemState equipped items cannot also be equip-enabled.")