class_name StoreState
extends RefCounted

const StoreItemStateScript = preload("res://src/ui/store_item_state.gd")

var wallet_coins: int
var items: Array[StoreItemStateScript] = []
var selected_item_id: StringName
var feedback_message: String

func _init(
	wallet_coins_value: int = 0,
	items_value: Array[StoreItemStateScript] = [],
	selected_item_id_value: StringName = StringName(),
	feedback_message_value: String = ""
) -> void:
	wallet_coins = wallet_coins_value
	items = items_value.duplicate()
	selected_item_id = selected_item_id_value
	feedback_message = feedback_message_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(wallet_coins >= 0, "StoreState wallet coins cannot be negative.")
	Validation.require_condition(not items.is_empty(), "StoreState requires at least one item.")

	var seen_item_ids: Dictionary[StringName, bool] = {}
	var selected_item_exists: bool = selected_item_id.is_empty()
	for item in items:
		Validation.require_condition(item != null, "StoreState cannot contain null item states.")
		Validation.require_condition(item is StoreItemStateScript, "StoreState requires StoreItemState entries.")
		item.assert_valid()
		Validation.require_condition(not seen_item_ids.has(item.item_id), "StoreState item ids must be unique.")
		seen_item_ids[item.item_id] = true
		if item.item_id == selected_item_id:
			selected_item_exists = true

	Validation.require_condition(selected_item_exists, "StoreState selected item id must exist in items.")