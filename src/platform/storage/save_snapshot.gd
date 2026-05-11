class_name SaveSnapshot
extends RefCounted

const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SELF_SCRIPT: GDScript = preload("res://src/platform/storage/save_snapshot.gd")

var schema_version: int
var wallet_coins: int

func _init(wallet_coin_count: int = 0, schema_version_value: int = SaveSchemaScript.VERSION) -> void:
    schema_version = schema_version_value
    wallet_coins = wallet_coin_count
    assert_valid()

static func is_dictionary_valid(payload: Dictionary) -> bool:
    if not payload.has(SaveSchemaScript.KEY_SCHEMA_VERSION):
        return false

    if not payload.has(SaveSchemaScript.KEY_WALLET_COINS):
        return false

    var raw_schema_version: Variant = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
    var raw_wallet_coins: Variant = payload[SaveSchemaScript.KEY_WALLET_COINS]

    if not raw_schema_version is int:
        return false

    if not raw_wallet_coins is int:
        return false

    return raw_schema_version == SaveSchemaScript.VERSION and raw_wallet_coins >= 0

static func assert_dictionary_valid(payload: Dictionary) -> void:
    Validation.require_condition(payload.has(SaveSchemaScript.KEY_SCHEMA_VERSION), "Save payload is missing schema version.")
    Validation.require_condition(payload.has(SaveSchemaScript.KEY_WALLET_COINS), "Save payload is missing wallet coins.")

    var raw_schema_version: Variant = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
    var raw_wallet_coins: Variant = payload[SaveSchemaScript.KEY_WALLET_COINS]

    Validation.require_condition(raw_schema_version is int, "Save schema version must be an integer.")
    Validation.require_condition(raw_wallet_coins is int, "Save wallet coins must be an integer.")

    var schema_version_value: int = raw_schema_version
    var wallet_coin_count: int = raw_wallet_coins

    Validation.require_condition(schema_version_value == SaveSchemaScript.VERSION, "Save schema version is unsupported.")
    Validation.require_condition(wallet_coin_count >= 0, "Save wallet coins cannot be negative.")

static func from_dictionary(payload: Dictionary) -> RefCounted:
    assert_dictionary_valid(payload)

    var wallet_coin_count: int = payload[SaveSchemaScript.KEY_WALLET_COINS]
    var schema_version_value: int = payload[SaveSchemaScript.KEY_SCHEMA_VERSION]
    return SELF_SCRIPT.new(wallet_coin_count, schema_version_value)

func is_valid() -> bool:
    return schema_version == SaveSchemaScript.VERSION and wallet_coins >= 0

func assert_valid() -> void:
    Validation.require_condition(schema_version == SaveSchemaScript.VERSION, "Save schema version is unsupported.")
    Validation.require_condition(wallet_coins >= 0, "Save wallet coins cannot be negative.")

func to_dictionary() -> Dictionary[String, int]:
    return {
        SaveSchemaScript.KEY_SCHEMA_VERSION: schema_version,
        SaveSchemaScript.KEY_WALLET_COINS: wallet_coins,
    }