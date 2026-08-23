class_name SettingsMenu
extends Control

signal closed
signal audio_muted_changed(audio_muted: bool)
signal master_volume_changed(master_volume_ratio: float)
signal haptics_enabled_changed(haptics_enabled: bool)
signal touch_split_changed(touch_split_ratio: float)
signal touch_center_dead_zone_changed(touch_center_dead_zone_ratio: float)

const SettingsStateScript = preload("res://src/ui/settings_state.gd")

@onready var _close_button: BaseButton = $CenterContainer/Panel/ControlPosition/CloseButton

@onready var _audio_mute_check_box: CheckBox = $CenterContainer/Panel/ControlPosition/AudioControl/AudioMuteCheckBox

@onready var _volume_slider: HSlider = $CenterContainer/Panel/ControlPosition/VolumeControl/VolumeSlider
@onready var _volume_value_label: Label = $CenterContainer/Panel/ControlPosition/VolumeControl/value_volume

@onready var _haptics_check_box: CheckBox = $CenterContainer/Panel/ControlPosition/HapicControl/HapticsCheckBox

@onready var _touch_split_slider: HSlider = $CenterContainer/Panel/ControlPosition/TouchSplitControl/TouchSplitSlider
@onready var _touch_split_value_label: Label = $CenterContainer/Panel/ControlPosition/TouchSplitControl/value_touchsplit

@onready var _touch_dead_zone_slider: HSlider = $CenterContainer/Panel/ControlPosition/TouchDeadZoneControl/TouchDeadZoneSlider
@onready var _touch_dead_zone_value_label: Label = $CenterContainer/Panel/ControlPosition/TouchDeadZoneControl/value_touchdead

var _applying_state: bool = false

func _ready() -> void:
	_validate_required_nodes()
	var _close_connect_result: int = _close_button.connect(&"pressed", Callable(self, "_on_close_requested"))
	var _audio_connect_result: int = _audio_mute_check_box.connect(&"toggled", Callable(self, "_on_audio_mute_toggled"))
	var _volume_connect_result: int = _volume_slider.connect(&"value_changed", Callable(self, "_on_volume_value_changed"))
	var _haptics_connect_result: int = _haptics_check_box.connect(&"toggled", Callable(self, "_on_haptics_toggled"))
	var _split_connect_result: int = _touch_split_slider.connect(&"value_changed", Callable(self, "_on_touch_split_value_changed"))
	var _dead_zone_connect_result: int = _touch_dead_zone_slider.connect(&"value_changed", Callable(self, "_on_touch_dead_zone_value_changed"))

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "SettingsMenu requires a state snapshot.")
	Validation.require_condition(state is SettingsStateScript, "SettingsMenu requires a SettingsState snapshot.")

	var typed_state: SettingsStateScript = state as SettingsStateScript
	typed_state.assert_valid()

	_applying_state = true

	visible = typed_state.visible
	_audio_mute_check_box.button_pressed = typed_state.audio_muted

	# 0.0 → 1.0 thành 0 → 100
	_volume_slider.value = typed_state.master_volume_ratio * 100.0

	_haptics_check_box.button_pressed = typed_state.haptics_enabled

	# 0.35 → 0.65 thành 0 → 100
	_touch_split_slider.value = inverse_lerp(
		0.35,
		0.65,
		typed_state.touch_split_ratio
	) * 100.0

	# 0.0 → 0.20 thành 0 → 100
	_touch_dead_zone_slider.value = inverse_lerp(
		0.0,
		0.20,
		typed_state.touch_center_dead_zone_ratio
	) * 100.0

	_refresh_value_labels()

	_applying_state = false

func _refresh_value_labels() -> void:
	_volume_value_label.text = "%d%%" % roundi(_volume_slider.value)
	_touch_split_value_label.text = "%d%%" % roundi(_touch_split_slider.value)
	_touch_dead_zone_value_label.text = "%d%%" % roundi(_touch_dead_zone_slider.value)

func _on_close_requested() -> void:
	closed.emit()

func _on_audio_mute_toggled(button_pressed: bool) -> void:
	if _applying_state:
		return

	audio_muted_changed.emit(button_pressed)

func _on_volume_value_changed(value: float) -> void:
	_refresh_value_labels()

	if _applying_state:
		return

	master_volume_changed.emit(value / 100.0)

func _on_haptics_toggled(button_pressed: bool) -> void:
	if _applying_state:
		return

	haptics_enabled_changed.emit(button_pressed)

func _on_touch_split_value_changed(value: float) -> void:
	_refresh_value_labels()

	if _applying_state:
		return

	var ratio: float = lerp(0.35, 0.65, value / 100.0)
	touch_split_changed.emit(ratio)

func _on_touch_dead_zone_value_changed(value: float) -> void:
	_refresh_value_labels()

	if _applying_state:
		return

	var ratio: float = lerp(0.0, 0.20, value / 100.0)
	touch_center_dead_zone_changed.emit(ratio)

func _validate_required_nodes() -> void:
	Validation.require_condition(_close_button != null, "SettingsMenu requires CloseButton.")
	Validation.require_condition(_audio_mute_check_box != null, "SettingsMenu requires AudioMuteCheckBox.")
	Validation.require_condition(_volume_slider != null, "SettingsMenu requires VolumeSlider.")
	Validation.require_condition(_volume_value_label != null, "SettingsMenu requires VolumeValueLabel.")
	Validation.require_condition(_haptics_check_box != null, "SettingsMenu requires HapticsCheckBox.")
	Validation.require_condition(_touch_split_slider != null, "SettingsMenu requires TouchSplitSlider.")
	Validation.require_condition(_touch_split_value_label != null, "SettingsMenu requires TouchSplitValueLabel.")
	Validation.require_condition(_touch_dead_zone_slider != null, "SettingsMenu requires TouchDeadZoneSlider.")
	Validation.require_condition(_touch_dead_zone_value_label != null, "SettingsMenu requires TouchDeadZoneValueLabel.")
