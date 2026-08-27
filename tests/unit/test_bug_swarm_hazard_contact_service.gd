extends GutTest

const BugSwarmHazardContactServiceScript = preload("res://src/gameplay/hazards/bug_swarm_hazard_contact_service.gd")
const HazardCameraEffectControllerScript = preload("res://src/gameplay/run/hazard_camera_effect_controller.gd")

func test_bug_swarm_hazard_contact_service_triggers_obscure_pulse_only() -> void:
	var camera_effect_controller: HazardCameraEffectControllerScript = HazardCameraEffectControllerScript.new()
	var service: BugSwarmHazardContactServiceScript = BugSwarmHazardContactServiceScript.new()

	assert_false(camera_effect_controller.has_active_shake())
	assert_false(camera_effect_controller.has_active_obscure_pulse())

	service.resolve(camera_effect_controller)

	assert_false(camera_effect_controller.has_active_shake())
	assert_true(camera_effect_controller.has_active_obscure_pulse())

	camera_effect_controller.advance(10.0)

	assert_false(camera_effect_controller.has_active_obscure_pulse())
