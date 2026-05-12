class_name StaminaFallService
extends RefCounted

const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")

func resolve(player: Node, run_session: RefCounted) -> void:
	Validation.require_condition(player != null, "StaminaFallService requires a player character.")
	Validation.require_condition(player is PlayerCharacterScript, "StaminaFallService requires a PlayerCharacter implementation.")
	Validation.require_condition(run_session != null, "StaminaFallService requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "StaminaFallService requires a RunSession implementation.")

	var typed_player: PlayerCharacterScript = player
	var typed_run_session: RunSessionScript = run_session

	typed_player.enter_falling(PlayerPhysicsModeTransitionsScript.Reason.STAMINA_DEPLETED)
	typed_run_session.begin_stamina_fall()
	typed_run_session.resolve_stamina_fall()