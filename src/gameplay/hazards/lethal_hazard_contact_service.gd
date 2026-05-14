class_name LethalHazardContactService
extends RefCounted

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")

func resolve(controller: RefCounted, player: Node, run_session: RefCounted) -> void:
	Validation.require_condition(controller != null, "LethalHazardContactService requires a climb controller.")
	Validation.require_condition(controller is ClimbPrototypeControllerScript, "LethalHazardContactService requires a ClimbPrototypeController implementation.")
	Validation.require_condition(player != null, "LethalHazardContactService requires a player character.")
	Validation.require_condition(player is PlayerCharacterScript, "LethalHazardContactService requires a PlayerCharacter implementation.")
	Validation.require_condition(run_session != null, "LethalHazardContactService requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "LethalHazardContactService requires a RunSession implementation.")

	var typed_controller: ClimbPrototypeControllerScript = controller as ClimbPrototypeControllerScript
	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	var typed_run_session: RunSessionScript = run_session as RunSessionScript

	typed_controller.get_attachment_state().release_all()
	typed_player.enter_falling(PlayerPhysicsModeTransitionsScript.Reason.FALL_DETECTED)
	typed_run_session.end_run(RunEndReasonScript.Value.LETHAL_HAZARD)