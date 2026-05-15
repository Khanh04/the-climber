class_name WindGustHazardContactService
extends RefCounted

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func resolve(controller: RefCounted, player: Node, run_session: RefCounted, impulse_vector_pixels: Vector2) -> void:
	Validation.require_condition(controller != null, "WindGustHazardContactService requires a climb controller.")
	Validation.require_condition(controller is ClimbPrototypeControllerScript, "WindGustHazardContactService requires a ClimbPrototypeController implementation.")
	Validation.require_condition(player != null, "WindGustHazardContactService requires a player character.")
	Validation.require_condition(player is PlayerCharacterScript, "WindGustHazardContactService requires a PlayerCharacter implementation.")
	Validation.require_condition(run_session != null, "WindGustHazardContactService requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "WindGustHazardContactService requires a RunSession implementation.")
	Validation.require_condition(impulse_vector_pixels != Vector2.ZERO, "WindGustHazardContactService requires a non-zero impulse vector.")

	var typed_controller: ClimbPrototypeControllerScript = controller as ClimbPrototypeControllerScript
	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	var typed_run_session: RunSessionScript = run_session as RunSessionScript
	var run_state: int = typed_run_session.get_state()

	Validation.require_condition(
		run_state == RunStateScript.Value.CLIMBING
			or run_state == RunStateScript.Value.FALLING
			or run_state == RunStateScript.Value.RESCUE_OFFERED,
		"WindGustHazardContactService can only resolve while the run is active."
	)

	if run_state == RunStateScript.Value.CLIMBING:
		typed_controller.get_attachment_state().release_all()
		typed_player.clear_runtime_grip_joints()
		typed_player.clear_runtime_grip_links()

	typed_player.set_body_linear_velocity(typed_player.get_body_linear_velocity() + impulse_vector_pixels)