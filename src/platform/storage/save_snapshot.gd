class_name SaveSnapshot
extends RefCounted

const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SELF_SCRIPT: GDScript = preload("res://src/platform/storage/save_snapshot.gd")

var schema_version: int
var wallet_coins: int
var chaser_theme_id: StringName

func _init(wallet_coin_count: int = 0, schema_version_value: int = SaveSchemaScript.VERSION, chaser_theme_id_value: StringName = &"rising_void") -> void:
    schema_version = schema_version_value
    wallet_coins = wallet_coin_count
    chaser_theme_id = chaser_theme_id_value
    assert_valid()

static func is_dictionary_valid(payload: Dictionary) -> bool:
    if not payload.has(SaveSchemaScript.KEY_SCHEMA_VERSION):
        return false

    if not payload.has(SaveSchemaScript.KEY_WALLET_COINS):
        return false

    if not payload.has(SaveSchemaScript.KEY_CHASER_THEME_ID):
        return false

    var raw_schema_version: Variant = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
    var raw_wallet_coins: Variant = payload[SaveSchemaScript.KEY_WALLET_COINS]
    var raw_chaser_theme_id: Variant = payload[SaveSchemaScript.KEY_CHASER_THEME_ID]

    if not raw_schema_version is int:
        return false

    if not raw_wallet_coins is int:
        return false

    if not (raw_chaser_theme_id is String or raw_chaser_theme_id is StringName):
        return false

    var chaser_theme_id_string: String = _theme_id_string_from_variant(raw_chaser_theme_id)
    return raw_schema_version == SaveSchemaScript.VERSION and raw_wallet_coins >= 0 and not chaser_theme_id_string.is_empty()

static func assert_dictionary_valid(payload: Dictionary) -> void:
    Validation.require_condition(payload.has(SaveSchemaScript.KEY_SCHEMA_VERSION), "Save payload is missing schema version.")
    Validation.require_condition(payload.has(SaveSchemaScript.KEY_WALLET_COINS), "Save payload is missing wallet coins.")
    Validation.require_condition(payload.has(SaveSchemaScript.KEY_CHASER_THEME_ID), "Save payload is missing chaser theme id.")

    var raw_schema_version: Variant = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
    var raw_wallet_coins: Variant = payload[SaveSchemaScript.KEY_WALLET_COINS]
    var raw_chaser_theme_id: Variant = payload[SaveSchemaScript.KEY_CHASER_THEME_ID]

    Validation.require_condition(raw_schema_version is int, "Save schema version must be an integer.")
    Validation.require_condition(raw_wallet_coins is int, "Save wallet coins must be an integer.")
    Validation.require_condition(raw_chaser_theme_id is String or raw_chaser_theme_id is StringName, "Save chaser theme id must be a string.")

    var schema_version_value: int = raw_schema_version
    var wallet_coin_count: int = raw_wallet_coins
    var chaser_theme_id_value: String = _theme_id_string_from_variant(raw_chaser_theme_id)

    Validation.require_condition(schema_version_value == SaveSchemaScript.VERSION, "Save schema version is unsupported.")
    Validation.require_condition(wallet_coin_count >= 0, "Save wallet coins cannot be negative.")
    Validation.require_condition(not chaser_theme_id_value.is_empty(), "Save chaser theme id cannot be empty.")

static func from_dictionary(payload: Dictionary) -> RefCounted:
    assert_dictionary_valid(payload)

    var wallet_coin_count: int = payload[SaveSchemaScript.KEY_WALLET_COINS]
    var schema_version_value: int = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
    var chaser_theme_id_value: StringName = StringName(_theme_id_string_from_variant(payload[SaveSchemaScript.KEY_CHASER_THEME_ID]))
    return SELF_SCRIPT.new(wallet_coin_count, schema_version_value, chaser_theme_id_value)

func is_valid() -> bool:
    return schema_version == SaveSchemaScript.VERSION and wallet_coins >= 0 and not chaser_theme_id.is_empty()

func assert_valid() -> void:
    Validation.require_condition(schema_version == SaveSchemaScript.VERSION, "Save schema version is unsupported.")
    Validation.require_condition(wallet_coins >= 0, "Save wallet coins cannot be negative.")
    Validation.require_condition(not chaser_theme_id.is_empty(), "Save chaser theme id cannot be empty.")

func to_dictionary() -> Dictionary:
    return {
        SaveSchemaScript.KEY_SCHEMA_VERSION: schema_version,
        SaveSchemaScript.KEY_WALLET_COINS: wallet_coins,
        SaveSchemaScript.KEY_CHASER_THEME_ID: _theme_id_string_from_string_name(chaser_theme_id),
    }

static func _theme_id_string_from_variant(raw_chaser_theme_id: Variant) -> String:
    if raw_chaser_theme_id is String:
        var raw_chaser_theme_id_string: String = raw_chaser_theme_id
        return raw_chaser_theme_id_string

    var raw_chaser_theme_id_name: StringName = raw_chaser_theme_id
    return _theme_id_string_from_string_name(raw_chaser_theme_id_name)

static func _theme_id_string_from_string_name(raw_chaser_theme_id: StringName) -> String:
    return String(raw_chaser_theme_id)