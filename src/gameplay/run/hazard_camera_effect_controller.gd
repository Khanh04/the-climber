class_name HazardCameraEffectController
extends RefCounted

var _overlay_layer: CanvasLayer = null
var _overlay_rect: ColorRect = null

var _shake_amplitude_pixels: float = 0.0
var _shake_remaining_seconds: float = 0.0
var _shake_duration_seconds: float = 0.0

var _obscure_peak_alpha: float = 0.0
var _obscure_remaining_seconds: float = 0.0
var _obscure_duration_seconds: float = 0.0

func ensure_overlay(parent: Node) -> void:
	Validation.require_condition(parent != null, "HazardCameraEffectController requires a parent node for its overlay.")
	if _overlay_layer != null:
		return

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = &"HazardObscureOverlayLayer"
	_overlay_layer.layer = 100
	parent.add_child(_overlay_layer)

	_overlay_rect = ColorRect.new()
	_overlay_rect.name = &"HazardObscureOverlayRect"
	_overlay_rect.color = Color(0.1, 0.1, 0.08, 0.0)
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.add_child(_overlay_rect)

func trigger_shake(amplitude_pixels: float, duration_seconds: float) -> void:
	Validation.require_condition(amplitude_pixels > 0.0, "HazardCameraEffectController shake amplitude must be positive.")
	Validation.require_condition(duration_seconds > 0.0, "HazardCameraEffectController shake duration must be positive.")
	_shake_amplitude_pixels = amplitude_pixels
	_shake_duration_seconds = duration_seconds
	_shake_remaining_seconds = duration_seconds

func trigger_obscure_pulse(peak_alpha: float, duration_seconds: float) -> void:
	Validation.require_condition(peak_alpha > 0.0, "HazardCameraEffectController obscure alpha must be positive.")
	Validation.require_condition(duration_seconds > 0.0, "HazardCameraEffectController obscure duration must be positive.")
	_obscure_peak_alpha = peak_alpha
	_obscure_duration_seconds = duration_seconds
	_obscure_remaining_seconds = duration_seconds

func advance(delta: float) -> void:
	Validation.require_condition(delta >= 0.0, "HazardCameraEffectController advance delta cannot be negative.")
	if _shake_remaining_seconds > 0.0:
		_shake_remaining_seconds = maxf(0.0, _shake_remaining_seconds - delta)

	if _obscure_remaining_seconds > 0.0:
		_obscure_remaining_seconds = maxf(0.0, _obscure_remaining_seconds - delta)

	if _overlay_rect != null:
		var obscure_ratio: float = 0.0
		if _obscure_duration_seconds > 0.0:
			obscure_ratio = _obscure_remaining_seconds / _obscure_duration_seconds
		_overlay_rect.color.a = _obscure_peak_alpha * obscure_ratio

func has_active_shake() -> bool:
	return _shake_remaining_seconds > 0.0

func has_active_obscure_pulse() -> bool:
	return _obscure_remaining_seconds > 0.0

func get_camera_shake_offset() -> Vector2:
	if _shake_remaining_seconds <= 0.0 or _shake_duration_seconds <= 0.0:
		return Vector2.ZERO

	var decay_ratio: float = _shake_remaining_seconds / _shake_duration_seconds
	var current_amplitude: float = _shake_amplitude_pixels * decay_ratio
	return Vector2(
		randf_range(-current_amplitude, current_amplitude),
		randf_range(-current_amplitude, current_amplitude)
	)
