class_name SaveSnapshot
extends RefCounted

const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SELF_SCRIPT: GDScript = preload("res://src/platform/storage/save_snapshot.gd")

var schema_version: int
var wallet_coins: int
var chaser_theme_id: StringName
var body_cosmetic_id: StringName
var left_hand_cosmetic_id: StringName
var right_hand_cosmetic_id: StringName
var owned_cosmetic_ids: PackedStringArray
var applied_persistent_transaction_ids: PackedStringArray

func _init(
	wallet_coin_count: int = 0,
	schema_version_value: int = SaveSchemaScript.VERSION,
	chaser_theme_id_value: StringName = &"rising_void",
	applied_persistent_transaction_ids_value: PackedStringArray = PackedStringArray(),
	owned_cosmetic_ids_value: PackedStringArray = PackedStringArray(),
	body_cosmetic_id_value: StringName = &"body_default",
	left_hand_cosmetic_id_value: StringName = &"left_hand_default",
	right_hand_cosmetic_id_value: StringName = &"right_hand_default"
) -> void:
	schema_version = schema_version_value
	wallet_coins = wallet_coin_count
	chaser_theme_id = chaser_theme_id_value
	body_cosmetic_id = body_cosmetic_id_value
	left_hand_cosmetic_id = left_hand_cosmetic_id_value
	right_hand_cosmetic_id = right_hand_cosmetic_id_value
	owned_cosmetic_ids = owned_cosmetic_ids_value.duplicate()
	applied_persistent_transaction_ids = applied_persistent_transaction_ids_value.duplicate()
	assert_valid()

static func is_dictionary_valid(payload: Dictionary) -> bool:
	if not payload.has(SaveSchemaScript.KEY_SCHEMA_VERSION):
		return false

	if not payload.has(SaveSchemaScript.KEY_WALLET_COINS):
		return false

	if not payload.has(SaveSchemaScript.KEY_CHASER_THEME_ID):
		return false

	if not payload.has(SaveSchemaScript.KEY_BODY_COSMETIC_ID):
		return false

	if not payload.has(SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID):
		return false

	if not payload.has(SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID):
		return false

	if not payload.has(SaveSchemaScript.KEY_OWNED_COSMETIC_IDS):
		return false

	if not payload.has(SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS):
		return false

	var raw_schema_version: Variant = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
	var raw_wallet_coins: Variant = payload[SaveSchemaScript.KEY_WALLET_COINS]
	var raw_chaser_theme_id: Variant = payload[SaveSchemaScript.KEY_CHASER_THEME_ID]
	var raw_body_cosmetic_id: Variant = payload[SaveSchemaScript.KEY_BODY_COSMETIC_ID]
	var raw_left_hand_cosmetic_id: Variant = payload[SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID]
	var raw_right_hand_cosmetic_id: Variant = payload[SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID]
	var raw_owned_cosmetic_ids: Variant = payload[SaveSchemaScript.KEY_OWNED_COSMETIC_IDS]
	var raw_applied_persistent_transaction_ids: Variant = payload[SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS]

	if not _is_integer_number_variant(raw_schema_version):
		return false

	if not _is_integer_number_variant(raw_wallet_coins):
		return false

	var schema_version_value: int = _integer_from_variant(raw_schema_version, "Save schema version must be an integer.")
	var wallet_coin_count: int = _integer_from_variant(raw_wallet_coins, "Save wallet coins must be an integer.")

	if not (raw_chaser_theme_id is String or raw_chaser_theme_id is StringName):
		return false

	if not (raw_body_cosmetic_id is String or raw_body_cosmetic_id is StringName):
		return false

	if not (raw_left_hand_cosmetic_id is String or raw_left_hand_cosmetic_id is StringName):
		return false

	if not (raw_right_hand_cosmetic_id is String or raw_right_hand_cosmetic_id is StringName):
		return false

	var chaser_theme_id_string: String = _theme_id_string_from_variant(raw_chaser_theme_id)
	var body_cosmetic_id_string: String = _string_id_from_variant(raw_body_cosmetic_id)
	var left_hand_cosmetic_id_string: String = _string_id_from_variant(raw_left_hand_cosmetic_id)
	var right_hand_cosmetic_id_string: String = _string_id_from_variant(raw_right_hand_cosmetic_id)
	return schema_version_value == SaveSchemaScript.VERSION \
		and wallet_coin_count >= 0 \
		and not chaser_theme_id_string.is_empty() \
		and not body_cosmetic_id_string.is_empty() \
		and not left_hand_cosmetic_id_string.is_empty() \
		and not right_hand_cosmetic_id_string.is_empty() \
		and _is_owned_cosmetic_id_collection_valid(raw_owned_cosmetic_ids) \
		and _is_transaction_id_collection_valid(raw_applied_persistent_transaction_ids)

static func assert_dictionary_valid(payload: Dictionary) -> void:
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_SCHEMA_VERSION), "Save payload is missing schema version.")
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_WALLET_COINS), "Save payload is missing wallet coins.")
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_CHASER_THEME_ID), "Save payload is missing chaser theme id.")
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_BODY_COSMETIC_ID), "Save payload is missing body cosmetic id.")
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID), "Save payload is missing left-hand cosmetic id.")
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID), "Save payload is missing right-hand cosmetic id.")
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_OWNED_COSMETIC_IDS), "Save payload is missing owned cosmetic ids.")
	Validation.require_condition(payload.has(SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS), "Save payload is missing applied persistent transaction ids.")

	var raw_schema_version: Variant = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
	var raw_wallet_coins: Variant = payload[SaveSchemaScript.KEY_WALLET_COINS]
	var raw_chaser_theme_id: Variant = payload[SaveSchemaScript.KEY_CHASER_THEME_ID]
	var raw_body_cosmetic_id: Variant = payload[SaveSchemaScript.KEY_BODY_COSMETIC_ID]
	var raw_left_hand_cosmetic_id: Variant = payload[SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID]
	var raw_right_hand_cosmetic_id: Variant = payload[SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID]
	var raw_owned_cosmetic_ids: Variant = payload[SaveSchemaScript.KEY_OWNED_COSMETIC_IDS]
	var raw_applied_persistent_transaction_ids: Variant = payload[SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS]

	var schema_version_value: int = _integer_from_variant(raw_schema_version, "Save schema version must be an integer.")
	var wallet_coin_count: int = _integer_from_variant(raw_wallet_coins, "Save wallet coins must be an integer.")
	Validation.require_condition(raw_chaser_theme_id is String or raw_chaser_theme_id is StringName, "Save chaser theme id must be a string.")
	Validation.require_condition(raw_body_cosmetic_id is String or raw_body_cosmetic_id is StringName, "Save body cosmetic id must be a string.")
	Validation.require_condition(raw_left_hand_cosmetic_id is String or raw_left_hand_cosmetic_id is StringName, "Save left-hand cosmetic id must be a string.")
	Validation.require_condition(raw_right_hand_cosmetic_id is String or raw_right_hand_cosmetic_id is StringName, "Save right-hand cosmetic id must be a string.")
	Validation.require_condition(
		raw_owned_cosmetic_ids is Array or raw_owned_cosmetic_ids is PackedStringArray,
		"Save owned cosmetic ids must be an array of strings."
	)
	Validation.require_condition(
		raw_applied_persistent_transaction_ids is Array or raw_applied_persistent_transaction_ids is PackedStringArray,
		"Save applied persistent transaction ids must be an array of strings."
	)

	var chaser_theme_id_value: String = _theme_id_string_from_variant(raw_chaser_theme_id)
	var body_cosmetic_id_value: String = _string_id_from_variant(raw_body_cosmetic_id)
	var left_hand_cosmetic_id_value: String = _string_id_from_variant(raw_left_hand_cosmetic_id)
	var right_hand_cosmetic_id_value: String = _string_id_from_variant(raw_right_hand_cosmetic_id)
	var cosmetic_ids: PackedStringArray = _owned_cosmetic_ids_from_variant(raw_owned_cosmetic_ids)
	var transaction_ids: PackedStringArray = _transaction_ids_from_variant(raw_applied_persistent_transaction_ids)

	Validation.require_condition(schema_version_value == SaveSchemaScript.VERSION, "Save schema version is unsupported.")
	Validation.require_condition(wallet_coin_count >= 0, "Save wallet coins cannot be negative.")
	Validation.require_condition(not chaser_theme_id_value.is_empty(), "Save chaser theme id cannot be empty.")
	Validation.require_condition(not body_cosmetic_id_value.is_empty(), "Save body cosmetic id cannot be empty.")
	Validation.require_condition(not left_hand_cosmetic_id_value.is_empty(), "Save left-hand cosmetic id cannot be empty.")
	Validation.require_condition(not right_hand_cosmetic_id_value.is_empty(), "Save right-hand cosmetic id cannot be empty.")
	Validation.require_condition(cosmetic_ids.size() >= 0, "Save owned cosmetic ids must be valid.")
	Validation.require_condition(transaction_ids.size() >= 0, "Save applied persistent transaction ids must be valid.")

static func from_dictionary(payload: Dictionary) -> RefCounted:
	assert_dictionary_valid(payload)

	var wallet_coin_count: int = _integer_from_variant(payload[SaveSchemaScript.KEY_WALLET_COINS], "Save wallet coins must be an integer.")
	var schema_version_value: int = _integer_from_variant(payload[SaveSchemaScript.KEY_SCHEMA_VERSION], "Save schema version must be an integer.")
	var chaser_theme_id_value: StringName = StringName(_theme_id_string_from_variant(payload[SaveSchemaScript.KEY_CHASER_THEME_ID]))
	var body_cosmetic_id_value: StringName = StringName(_string_id_from_variant(payload[SaveSchemaScript.KEY_BODY_COSMETIC_ID]))
	var left_hand_cosmetic_id_value: StringName = StringName(_string_id_from_variant(payload[SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID]))
	var right_hand_cosmetic_id_value: StringName = StringName(_string_id_from_variant(payload[SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID]))
	var owned_ids: PackedStringArray = _owned_cosmetic_ids_from_variant(payload[SaveSchemaScript.KEY_OWNED_COSMETIC_IDS])
	var transaction_ids: PackedStringArray = _transaction_ids_from_variant(payload[SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS])
	return SELF_SCRIPT.new(wallet_coin_count, schema_version_value, chaser_theme_id_value, transaction_ids, owned_ids, body_cosmetic_id_value, left_hand_cosmetic_id_value, right_hand_cosmetic_id_value)

func is_valid() -> bool:
	return schema_version == SaveSchemaScript.VERSION \
		and wallet_coins >= 0 \
		and not chaser_theme_id.is_empty() \
		and not body_cosmetic_id.is_empty() \
		and not left_hand_cosmetic_id.is_empty() \
		and not right_hand_cosmetic_id.is_empty() \
		and _is_owned_cosmetic_id_collection_valid(owned_cosmetic_ids) \
		and _is_transaction_id_collection_valid(applied_persistent_transaction_ids)

func assert_valid() -> void:
	Validation.require_condition(schema_version == SaveSchemaScript.VERSION, "Save schema version is unsupported.")
	Validation.require_condition(wallet_coins >= 0, "Save wallet coins cannot be negative.")
	Validation.require_condition(not chaser_theme_id.is_empty(), "Save chaser theme id cannot be empty.")
	Validation.require_condition(not body_cosmetic_id.is_empty(), "Save body cosmetic id cannot be empty.")
	Validation.require_condition(not left_hand_cosmetic_id.is_empty(), "Save left-hand cosmetic id cannot be empty.")
	Validation.require_condition(not right_hand_cosmetic_id.is_empty(), "Save right-hand cosmetic id cannot be empty.")
	var _cosmetic_ids: PackedStringArray = _owned_cosmetic_ids_from_variant(owned_cosmetic_ids)
	var _transaction_ids: PackedStringArray = _transaction_ids_from_variant(applied_persistent_transaction_ids)

func to_dictionary() -> Dictionary:
	return {
		SaveSchemaScript.KEY_SCHEMA_VERSION: schema_version,
		SaveSchemaScript.KEY_WALLET_COINS: wallet_coins,
		SaveSchemaScript.KEY_CHASER_THEME_ID: _theme_id_string_from_string_name(chaser_theme_id),
		SaveSchemaScript.KEY_BODY_COSMETIC_ID: _theme_id_string_from_string_name(body_cosmetic_id),
		SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: _theme_id_string_from_string_name(left_hand_cosmetic_id),
		SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: _theme_id_string_from_string_name(right_hand_cosmetic_id),
		SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: _owned_cosmetic_ids_to_array(owned_cosmetic_ids),
		SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: _transaction_ids_to_array(applied_persistent_transaction_ids),
	}

static func _theme_id_string_from_variant(raw_chaser_theme_id: Variant) -> String:
	if raw_chaser_theme_id is String:
		var raw_chaser_theme_id_string: String = raw_chaser_theme_id
		return raw_chaser_theme_id_string

	var raw_chaser_theme_id_name: StringName = raw_chaser_theme_id
	return _theme_id_string_from_string_name(raw_chaser_theme_id_name)

static func _theme_id_string_from_string_name(raw_chaser_theme_id: StringName) -> String:
	return String(raw_chaser_theme_id)

static func _is_integer_number_variant(raw_value: Variant) -> bool:
	if raw_value is int:
		return true

	if raw_value is float:
		var raw_float: float = raw_value
		return raw_float == float(floori(raw_float))

	return false

static func _integer_from_variant(raw_value: Variant, validation_message: String) -> int:
	Validation.require_condition(_is_integer_number_variant(raw_value), validation_message)
	if raw_value is int:
		var raw_int: int = raw_value
		return raw_int

	var raw_float: float = raw_value
	return int(raw_float)

static func _is_transaction_id_collection_valid(raw_transaction_ids: Variant) -> bool:
	var parsed_transaction_ids: PackedStringArray = PackedStringArray()

	if raw_transaction_ids is PackedStringArray:
		var packed_transaction_ids: PackedStringArray = raw_transaction_ids
		for transaction_id: String in packed_transaction_ids:
			if transaction_id.is_empty():
				return false

			if parsed_transaction_ids.has(transaction_id):
				return false

			var _append_result: bool = parsed_transaction_ids.append(transaction_id)
		return true

	if raw_transaction_ids is Array:
		var raw_transaction_id_array: Array = raw_transaction_ids
		for raw_transaction_id: Variant in raw_transaction_id_array:
			if not (raw_transaction_id is String or raw_transaction_id is StringName):
				return false

			var transaction_id_string: String = _transaction_id_string_from_variant(raw_transaction_id)
			if transaction_id_string.is_empty():
				return false

			if parsed_transaction_ids.has(transaction_id_string):
				return false

			var _append_result: bool = parsed_transaction_ids.append(transaction_id_string)
		return true

	return false

static func _is_owned_cosmetic_id_collection_valid(raw_cosmetic_ids: Variant) -> bool:
	var parsed_cosmetic_ids: PackedStringArray = PackedStringArray()

	if raw_cosmetic_ids is PackedStringArray:
		var packed_cosmetic_ids: PackedStringArray = raw_cosmetic_ids
		for cosmetic_id: String in packed_cosmetic_ids:
			if cosmetic_id.is_empty():
				return false

			if parsed_cosmetic_ids.has(cosmetic_id):
				return false

			var _append_result: bool = parsed_cosmetic_ids.append(cosmetic_id)
		return true

	if raw_cosmetic_ids is Array:
		var raw_cosmetic_id_array: Array = raw_cosmetic_ids
		for raw_cosmetic_id: Variant in raw_cosmetic_id_array:
			if not (raw_cosmetic_id is String or raw_cosmetic_id is StringName):
				return false

			var cosmetic_id_string: String = _string_id_from_variant(raw_cosmetic_id)
			if cosmetic_id_string.is_empty():
				return false

			if parsed_cosmetic_ids.has(cosmetic_id_string):
				return false

			var _append_result: bool = parsed_cosmetic_ids.append(cosmetic_id_string)
		return true

	return false

static func _transaction_ids_from_variant(raw_transaction_ids: Variant) -> PackedStringArray:
	Validation.require_condition(
		raw_transaction_ids is Array or raw_transaction_ids is PackedStringArray,
		"Save applied persistent transaction ids must be an array of strings."
	)

	var parsed_transaction_ids: PackedStringArray = PackedStringArray()
	if raw_transaction_ids is PackedStringArray:
		var packed_transaction_ids: PackedStringArray = raw_transaction_ids
		for transaction_id: String in packed_transaction_ids:
			Validation.require_condition(not transaction_id.is_empty(), "Save applied persistent transaction ids cannot contain empty ids.")
			Validation.require_condition(not parsed_transaction_ids.has(transaction_id), "Save applied persistent transaction ids cannot contain duplicate ids.")
			var _append_result: bool = parsed_transaction_ids.append(transaction_id)
		return parsed_transaction_ids

	var raw_transaction_id_array: Array = raw_transaction_ids
	for raw_transaction_id: Variant in raw_transaction_id_array:
		Validation.require_condition(
			raw_transaction_id is String or raw_transaction_id is StringName,
			"Save applied persistent transaction ids must contain only strings."
		)
		var transaction_id_string: String = _transaction_id_string_from_variant(raw_transaction_id)
		Validation.require_condition(not transaction_id_string.is_empty(), "Save applied persistent transaction ids cannot contain empty ids.")
		Validation.require_condition(not parsed_transaction_ids.has(transaction_id_string), "Save applied persistent transaction ids cannot contain duplicate ids.")
		var _append_result: bool = parsed_transaction_ids.append(transaction_id_string)

	return parsed_transaction_ids

static func _owned_cosmetic_ids_from_variant(raw_cosmetic_ids: Variant) -> PackedStringArray:
	Validation.require_condition(
		raw_cosmetic_ids is Array or raw_cosmetic_ids is PackedStringArray,
		"Save owned cosmetic ids must be an array of strings."
	)

	var parsed_cosmetic_ids: PackedStringArray = PackedStringArray()
	if raw_cosmetic_ids is PackedStringArray:
		var packed_cosmetic_ids: PackedStringArray = raw_cosmetic_ids
		for cosmetic_id: String in packed_cosmetic_ids:
			Validation.require_condition(not cosmetic_id.is_empty(), "Save owned cosmetic ids cannot contain empty ids.")
			Validation.require_condition(not parsed_cosmetic_ids.has(cosmetic_id), "Save owned cosmetic ids cannot contain duplicate ids.")
			var _append_result: bool = parsed_cosmetic_ids.append(cosmetic_id)
		return parsed_cosmetic_ids

	var raw_cosmetic_id_array: Array = raw_cosmetic_ids
	for raw_cosmetic_id: Variant in raw_cosmetic_id_array:
		Validation.require_condition(
			raw_cosmetic_id is String or raw_cosmetic_id is StringName,
			"Save owned cosmetic ids must contain only strings."
		)
		var cosmetic_id_string: String = _string_id_from_variant(raw_cosmetic_id)
		Validation.require_condition(not cosmetic_id_string.is_empty(), "Save owned cosmetic ids cannot contain empty ids.")
		Validation.require_condition(not parsed_cosmetic_ids.has(cosmetic_id_string), "Save owned cosmetic ids cannot contain duplicate ids.")
		var _append_result: bool = parsed_cosmetic_ids.append(cosmetic_id_string)

	return parsed_cosmetic_ids

static func _transaction_ids_to_array(transaction_ids: PackedStringArray) -> Array[String]:
	var serialized_transaction_ids: Array[String] = []
	for transaction_id: String in transaction_ids:
		serialized_transaction_ids.append(transaction_id)
	return serialized_transaction_ids

static func _owned_cosmetic_ids_to_array(cosmetic_ids: PackedStringArray) -> Array[String]:
	var serialized_cosmetic_ids: Array[String] = []
	for cosmetic_id: String in cosmetic_ids:
		serialized_cosmetic_ids.append(cosmetic_id)
	return serialized_cosmetic_ids

static func _transaction_id_string_from_variant(raw_transaction_id: Variant) -> String:
	if raw_transaction_id is String:
		var raw_transaction_id_string: String = raw_transaction_id
		return raw_transaction_id_string

	var raw_transaction_id_name: StringName = raw_transaction_id
	return String(raw_transaction_id_name)

static func _string_id_from_variant(raw_id: Variant) -> String:
	if raw_id is String:
		var raw_string_id: String = raw_id
		return raw_string_id

	var raw_string_name_id: StringName = raw_id
	return String(raw_string_name_id)
