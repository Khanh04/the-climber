class_name RunHudState
extends RefCounted

const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

var height_meters: float = 0.0
var current_stamina_seconds: float = 0.0
var max_stamina_seconds: float = 0.0
var wallet_coins: int = 0
var run_earned_coins: int = 0
var run_state: int = RunStateScript.Value.READY

func _init(
	height_meters_value: float = 0.0,
	current_stamina_seconds_value: float = 0.0,
	max_stamina_seconds_value: float = 0.0,
	wallet_coins_value: int = 0,
	run_earned_coins_value: int = 0,
	run_state_value: int = RunStateScript.Value.READY
) -> void:
	height_meters = height_meters_value
	current_stamina_seconds = current_stamina_seconds_value
	max_stamina_seconds = max_stamina_seconds_value
	wallet_coins = wallet_coins_value
	run_earned_coins = run_earned_coins_value
	run_state = run_state_value

func assert_valid() -> void:
	Validation.require_condition(height_meters >= 0.0, "RunHudState height cannot be negative.")
	Validation.require_condition(current_stamina_seconds >= 0.0, "RunHudState current stamina cannot be negative.")
	Validation.require_condition(max_stamina_seconds > 0.0, "RunHudState max stamina must be positive.")
	Validation.require_condition(current_stamina_seconds <= max_stamina_seconds, "RunHudState current stamina cannot exceed max stamina.")
	Validation.require_condition(wallet_coins >= 0, "RunHudState wallet coins cannot be negative.")
	Validation.require_condition(run_earned_coins >= 0, "RunHudState run-earned coins cannot be negative.")
	RunStateScript.assert_valid(run_state)