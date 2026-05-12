class_name ChaserContactService
extends RefCounted

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")

func resolve(controller: RefCounted, player: Node, run_session: RefCounted) -> void:
	Validation.require_condition(controller != null, "ChaserContactService requires a climb controller.")
	Validation.require_condition(controller is ClimbPrototypeControllerScript, "ChaserContactService requires a ClimbPrototypeController implementation.")
	Validation.require_condition(player != null, "ChaserContactService requires a player character.")
	Validation.require_condition(player is PlayerCharacterScript, "ChaserContactService requires a PlayerCharacter implementation.")
	Validation.require_condition(run_session != null, "ChaserContactService requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "ChaserContactService requires a RunSession implementation.")

	var typed_controller: ClimbPrototypeControllerScript = controller
	var typed_player: PlayerCharacterScript = player
	var typed_run_session: RunSessionScript = run_session

	typed_controller.get_attachment_state().release_all()
	typed_player.enter_falling(PlayerPhysicsModeTransitionsScript.Reason.FALL_DETECTED)
	typed_run_session.end_run(RunEndReasonScript.Value.CHASER_CONTACT)