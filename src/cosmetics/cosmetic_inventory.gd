class_name CosmeticInventory
extends RefCounted

var _owned_item_ids: PackedStringArray = PackedStringArray()

func _init(
	initial_owned_item_ids: PackedStringArray = PackedStringArray(),
	default_owned_item_ids: PackedStringArray = PackedStringArray()
) -> void:
	_assert_id_collection_valid(initial_owned_item_ids, "CosmeticInventory initial owned item ids must be non-empty and unique.")
	_assert_id_collection_valid(default_owned_item_ids, "CosmeticInventory default owned item ids must be non-empty and unique.")
	_owned_item_ids = PackedStringArray()
	_append_unique_ids(default_owned_item_ids)
	_append_unique_ids(initial_owned_item_ids)
	assert_valid()

func is_owned(item_id: StringName) -> bool:
	Validation.require_condition(not item_id.is_empty(), "CosmeticInventory lookup item id cannot be empty.")
	return _owned_item_ids.has(String(item_id))

func unlock(item_id: StringName) -> bool:
	Validation.require_condition(not item_id.is_empty(), "CosmeticInventory unlock item id cannot be empty.")
	var item_id_string: String = String(item_id)
	if _owned_item_ids.has(item_id_string):
		return false

	var _append_result: bool = _owned_item_ids.append(item_id_string)
	return true

func get_owned_item_ids() -> PackedStringArray:
	return _owned_item_ids.duplicate()

func is_valid() -> bool:
	return _is_id_collection_valid(_owned_item_ids)

func assert_valid() -> void:
	Validation.require_condition(is_valid(), "CosmeticInventory requires non-empty unique owned item ids.")

func _append_unique_ids(item_ids: PackedStringArray) -> void:
	for item_id: String in item_ids:
		if not _owned_item_ids.has(item_id):
			var _append_result: bool = _owned_item_ids.append(item_id)

func _assert_id_collection_valid(item_ids: PackedStringArray, message: String) -> void:
	Validation.require_condition(_is_id_collection_valid(item_ids), message)

func _is_id_collection_valid(item_ids: PackedStringArray) -> bool:
	var seen_item_ids: PackedStringArray = PackedStringArray()
	for item_id: String in item_ids:
		if item_id.is_empty():
			return false

		if seen_item_ids.has(item_id):
			return false

		var _append_result: bool = seen_item_ids.append(item_id)

	return true