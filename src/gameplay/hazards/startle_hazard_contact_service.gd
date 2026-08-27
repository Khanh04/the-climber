class_name StartleHazardContactService
extends RefCounted

const HazardCameraEffectControllerScript = preload("res://src/gameplay/run/hazard_camera_effect_controller.gd")

const SHAKE_AMPLITUDE_PIXELS: float = 10.0
const SHAKE_DURATION_SECONDS: float = 0.4

func resolve(camera_effect_controller: RefCounted) -> void:
	Validation.require_condition(camera_effect_controller != null, "StartleHazardContactService requires a camera effect controller.")
	Validation.require_condition(camera_effect_controller is HazardCameraEffectControllerScript, "StartleHazardContactService requires a HazardCameraEffectController implementation.")

	var typed_camera_effect_controller: HazardCameraEffectControllerScript = camera_effect_controller as HazardCameraEffectControllerScript
	typed_camera_effect_controller.trigger_shake(SHAKE_AMPLITUDE_PIXELS, SHAKE_DURATION_SECONDS)
