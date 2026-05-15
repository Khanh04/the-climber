class_name AppSettingsSnapshot
extends RefCounted

const AppSettingsSchemaScript = preload("res://src/platform/storage/app_settings_schema.gd")
const SELF_SCRIPT: GDScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const TouchInputSettingsScript = preload("res://src/gameplay/player/touch_input_settings.gd")

var schema_version: int
var audio_muted: bool
var master_volume_ratio: float
var haptics_enabled: bool
var touch_split_ratio: float
var touch_center_dead_zone_ratio: float

func _init(
    schema_version_value: int = AppSettingsSchemaScript.VERSION,
    audio_muted_value: bool = false,
    master_volume_ratio_value: float = 1.0,
    haptics_enabled_value: bool = true,
    touch_split_ratio_value: float = 0.5,
    touch_center_dead_zone_ratio_value: float = 0.0
) -> void:
    schema_version = schema_version_value
    audio_muted = audio_muted_value
    master_volume_ratio = master_volume_ratio_value
    haptics_enabled = haptics_enabled_value
    touch_split_ratio = touch_split_ratio_value
    touch_center_dead_zone_ratio = touch_center_dead_zone_ratio_value
    assert_valid()

static func is_dictionary_valid(payload: Dictionary) -> bool:
    if not payload.has(AppSettingsSchemaScript.KEY_SCHEMA_VERSION):
        return false

    if not payload.has(AppSettingsSchemaScript.KEY_AUDIO_MUTED):
        return false

    if not payload.has(AppSettingsSchemaScript.KEY_MASTER_VOLUME_RATIO):
        return false

    if not payload.has(AppSettingsSchemaScript.KEY_HAPTICS_ENABLED):
        return false

    if not payload.has(AppSettingsSchemaScript.KEY_TOUCH_SPLIT_RATIO):
        return false

    if not payload.has(AppSettingsSchemaScript.KEY_TOUCH_CENTER_DEAD_ZONE_RATIO):
        return false

    var raw_schema_version: Variant = payload[AppSettingsSchemaScript.KEY_SCHEMA_VERSION]
    var raw_audio_muted: Variant = payload[AppSettingsSchemaScript.KEY_AUDIO_MUTED]
    var raw_master_volume_ratio: Variant = payload[AppSettingsSchemaScript.KEY_MASTER_VOLUME_RATIO]
    var raw_haptics_enabled: Variant = payload[AppSettingsSchemaScript.KEY_HAPTICS_ENABLED]
    var raw_touch_split_ratio: Variant = payload[AppSettingsSchemaScript.KEY_TOUCH_SPLIT_RATIO]
    var raw_touch_center_dead_zone_ratio: Variant = payload[AppSettingsSchemaScript.KEY_TOUCH_CENTER_DEAD_ZONE_RATIO]

    if not _is_integer_number_variant(raw_schema_version):
        return false

    if not raw_audio_muted is bool:
        return false

    if not _is_number_variant(raw_master_volume_ratio):
        return false

    if not raw_haptics_enabled is bool:
        return false

    if not _is_number_variant(raw_touch_split_ratio):
        return false

    if not _is_number_variant(raw_touch_center_dead_zone_ratio):
        return false

    var schema_version_value: int = _integer_from_variant(raw_schema_version, "App settings schema version must be an integer.")
    var master_volume_ratio_value: float = _float_from_variant(raw_master_volume_ratio, "App settings master volume ratio must be a number.")
    var touch_split_ratio_value: float = _float_from_variant(raw_touch_split_ratio, "App settings touch split ratio must be a number.")
    var touch_center_dead_zone_ratio_value: float = _float_from_variant(raw_touch_center_dead_zone_ratio, "App settings touch center dead-zone ratio must be a number.")

    return schema_version_value == AppSettingsSchemaScript.VERSION \
        and master_volume_ratio_value >= 0.0 \
        and master_volume_ratio_value <= 1.0 \
        and TouchInputSettingsScript.are_values_valid(touch_split_ratio_value, touch_center_dead_zone_ratio_value)

static func assert_dictionary_valid(payload: Dictionary) -> void:
    Validation.require_condition(payload.has(AppSettingsSchemaScript.KEY_SCHEMA_VERSION), "App settings payload is missing schema version.")
    Validation.require_condition(payload.has(AppSettingsSchemaScript.KEY_AUDIO_MUTED), "App settings payload is missing audio muted flag.")
    Validation.require_condition(payload.has(AppSettingsSchemaScript.KEY_MASTER_VOLUME_RATIO), "App settings payload is missing master volume ratio.")
    Validation.require_condition(payload.has(AppSettingsSchemaScript.KEY_HAPTICS_ENABLED), "App settings payload is missing haptics enabled flag.")
    Validation.require_condition(payload.has(AppSettingsSchemaScript.KEY_TOUCH_SPLIT_RATIO), "App settings payload is missing touch split ratio.")
    Validation.require_condition(payload.has(AppSettingsSchemaScript.KEY_TOUCH_CENTER_DEAD_ZONE_RATIO), "App settings payload is missing touch center dead-zone ratio.")

    var raw_schema_version: Variant = payload[AppSettingsSchemaScript.KEY_SCHEMA_VERSION]
    var raw_audio_muted: Variant = payload[AppSettingsSchemaScript.KEY_AUDIO_MUTED]
    var raw_master_volume_ratio: Variant = payload[AppSettingsSchemaScript.KEY_MASTER_VOLUME_RATIO]
    var raw_haptics_enabled: Variant = payload[AppSettingsSchemaScript.KEY_HAPTICS_ENABLED]
    var raw_touch_split_ratio: Variant = payload[AppSettingsSchemaScript.KEY_TOUCH_SPLIT_RATIO]
    var raw_touch_center_dead_zone_ratio: Variant = payload[AppSettingsSchemaScript.KEY_TOUCH_CENTER_DEAD_ZONE_RATIO]

    var schema_version_value: int = _integer_from_variant(raw_schema_version, "App settings schema version must be an integer.")
    Validation.require_condition(raw_audio_muted is bool, "App settings audio muted flag must be a boolean.")
    var master_volume_ratio_value: float = _float_from_variant(raw_master_volume_ratio, "App settings master volume ratio must be a number.")
    Validation.require_condition(raw_haptics_enabled is bool, "App settings haptics enabled flag must be a boolean.")
    var touch_split_ratio_value: float = _float_from_variant(raw_touch_split_ratio, "App settings touch split ratio must be a number.")
    var touch_center_dead_zone_ratio_value: float = _float_from_variant(raw_touch_center_dead_zone_ratio, "App settings touch center dead-zone ratio must be a number.")

    Validation.require_condition(schema_version_value == AppSettingsSchemaScript.VERSION, "App settings schema version is unsupported.")
    Validation.require_condition(master_volume_ratio_value >= 0.0 and master_volume_ratio_value <= 1.0, "App settings master volume ratio must be between 0 and 1.")
    var touch_settings: TouchInputSettingsScript = TouchInputSettingsScript.new(touch_split_ratio_value, touch_center_dead_zone_ratio_value)
    touch_settings.assert_valid()

static func from_dictionary(payload: Dictionary) -> AppSettingsSnapshot:
    assert_dictionary_valid(payload)
    var audio_muted_value: bool = payload[AppSettingsSchemaScript.KEY_AUDIO_MUTED]
    var haptics_enabled_value: bool = payload[AppSettingsSchemaScript.KEY_HAPTICS_ENABLED]
    return SELF_SCRIPT.new(
        _integer_from_variant(payload[AppSettingsSchemaScript.KEY_SCHEMA_VERSION], "App settings schema version must be an integer."),
        audio_muted_value,
        _float_from_variant(payload[AppSettingsSchemaScript.KEY_MASTER_VOLUME_RATIO], "App settings master volume ratio must be a number."),
        haptics_enabled_value,
        _float_from_variant(payload[AppSettingsSchemaScript.KEY_TOUCH_SPLIT_RATIO], "App settings touch split ratio must be a number."),
        _float_from_variant(payload[AppSettingsSchemaScript.KEY_TOUCH_CENTER_DEAD_ZONE_RATIO], "App settings touch center dead-zone ratio must be a number.")
    )

func is_valid() -> bool:
    return schema_version == AppSettingsSchemaScript.VERSION \
        and master_volume_ratio >= 0.0 \
        and master_volume_ratio <= 1.0 \
        and TouchInputSettingsScript.are_values_valid(touch_split_ratio, touch_center_dead_zone_ratio)

func assert_valid() -> void:
    Validation.require_condition(schema_version == AppSettingsSchemaScript.VERSION, "App settings schema version is unsupported.")
    Validation.require_condition(master_volume_ratio >= 0.0 and master_volume_ratio <= 1.0, "App settings master volume ratio must be between 0 and 1.")
    var touch_settings: TouchInputSettingsScript = TouchInputSettingsScript.new(touch_split_ratio, touch_center_dead_zone_ratio)
    touch_settings.assert_valid()

func to_dictionary() -> Dictionary:
    assert_valid()
    return {
        AppSettingsSchemaScript.KEY_SCHEMA_VERSION: schema_version,
        AppSettingsSchemaScript.KEY_AUDIO_MUTED: audio_muted,
        AppSettingsSchemaScript.KEY_MASTER_VOLUME_RATIO: master_volume_ratio,
        AppSettingsSchemaScript.KEY_HAPTICS_ENABLED: haptics_enabled,
        AppSettingsSchemaScript.KEY_TOUCH_SPLIT_RATIO: touch_split_ratio,
        AppSettingsSchemaScript.KEY_TOUCH_CENTER_DEAD_ZONE_RATIO: touch_center_dead_zone_ratio,
    }

func to_touch_input_settings() -> TouchInputSettingsScript:
    return TouchInputSettingsScript.new(touch_split_ratio, touch_center_dead_zone_ratio)

static func _is_integer_number_variant(raw_value: Variant) -> bool:
    if raw_value is int:
        return true

    if raw_value is float:
        var raw_float: float = raw_value
        return raw_float == float(floori(raw_float))

    return false

static func _is_number_variant(raw_value: Variant) -> bool:
    return raw_value is int or raw_value is float

static func _integer_from_variant(raw_value: Variant, validation_message: String) -> int:
    Validation.require_condition(_is_integer_number_variant(raw_value), validation_message)
    if raw_value is int:
        var raw_int: int = raw_value
        return raw_int

    var raw_float: float = raw_value
    return int(raw_float)

static func _float_from_variant(raw_value: Variant, validation_message: String) -> float:
    Validation.require_condition(_is_number_variant(raw_value), validation_message)
    if raw_value is float:
        var raw_float: float = raw_value
        return raw_float

    var raw_int: int = raw_value
    return float(raw_int)