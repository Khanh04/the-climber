extends GutTest

const StartleHazardContactServiceScript = preload("res://src/gameplay/hazards/startle_hazard_contact_service.gd")
const HazardCameraEffectControllerScript = preload("res://src/gameplay/run/hazard_camera_effect_controller.gd")

func test_startle_hazard_contact_service_triggers_camera_shake_only() -> void:
	var camera_effect_controller: HazardCameraEffectControllerScript = HazardCameraEffectControllerScript.new()
	var service: StartleHazardContactServiceScript = StartleHazardContactServiceScript.new()

	assert_false(camera_effect_controller.has_active_shake())
	assert_false(camera_effect_controller.has_active_obscure_pulse())

	service.resolve(camera_effect_controller)

	assert_true(camera_effect_controller.has_active_shake())
	assert_false(camera_effect_controller.has_active_obscure_pulse())

	camera_effect_controller.advance(10.0)

	assert_false(camera_effect_controller.has_active_shake())
