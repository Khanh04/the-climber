class_name BugSwarmHazardContactService
extends RefCounted

const HazardCameraEffectControllerScript = preload("res://src/gameplay/run/hazard_camera_effect_controller.gd")

const OBSCURE_PEAK_ALPHA: float = 0.55
const OBSCURE_DURATION_SECONDS: float = 1.5

func resolve(camera_effect_controller: RefCounted) -> void:
	Validation.require_condition(camera_effect_controller != null, "BugSwarmHazardContactService requires a camera effect controller.")
	Validation.require_condition(camera_effect_controller is HazardCameraEffectControllerScript, "BugSwarmHazardContactService requires a HazardCameraEffectController implementation.")

	var typed_camera_effect_controller: HazardCameraEffectControllerScript = camera_effect_controller as HazardCameraEffectControllerScript
	typed_camera_effect_controller.trigger_obscure_pulse(OBSCURE_PEAK_ALPHA, OBSCURE_DURATION_SECONDS)
