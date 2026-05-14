class_name NormalCoinPickupService
extends RefCounted

const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")

func resolve(body: Node, player: Node, run_session: RefCounted, coin_amount: int) -> bool:
	Validation.require_condition(body != null, "NormalCoinPickupService requires a body.")
	Validation.require_condition(player != null, "NormalCoinPickupService requires a player character.")
	Validation.require_condition(player is PlayerCharacterScript, "NormalCoinPickupService requires a PlayerCharacter implementation.")
	Validation.require_condition(run_session != null, "NormalCoinPickupService requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "NormalCoinPickupService requires a RunSession implementation.")
	Validation.require_condition(coin_amount > 0, "NormalCoinPickupService coin amount must be positive.")

	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	if body != typed_player.get_player_body():
		return false

	var typed_run_session: RunSessionScript = run_session as RunSessionScript
	typed_run_session.add_run_earned_coins(coin_amount)
	return true