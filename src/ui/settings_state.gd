class_name SettingsState
extends RefCounted

const TouchInputSettingsScript = preload("res://src/gameplay/player/touch_input_settings.gd")

var visible: bool
var audio_muted: bool
var master_volume_ratio: float
var haptics_enabled: bool
var touch_split_ratio: float
var touch_center_dead_zone_ratio: float

func _init(
    visible_value: bool = false,
    audio_muted_value: bool = false,
    master_volume_ratio_value: float = 1.0,
    haptics_enabled_value: bool = true,
    touch_split_ratio_value: float = 0.5,
    touch_center_dead_zone_ratio_value: float = 0.0
) -> void:
    visible = visible_value
    audio_muted = audio_muted_value
    master_volume_ratio = master_volume_ratio_value
    haptics_enabled = haptics_enabled_value
    touch_split_ratio = touch_split_ratio_value
    touch_center_dead_zone_ratio = touch_center_dead_zone_ratio_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(master_volume_ratio >= 0.0 and master_volume_ratio <= 1.0, "SettingsState master volume ratio must be between 0 and 1.")
    Validation.require_condition(
        TouchInputSettingsScript.are_values_valid(touch_split_ratio, touch_center_dead_zone_ratio),
        "SettingsState touch settings must stay within the supported mobile control range."
    )