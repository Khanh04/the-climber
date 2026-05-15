class_name PauseMenuState
extends RefCounted

var visible: bool
var height_meters: float
var wallet_coins: int
var run_earned_coins: int

func _init(
	visible_value: bool = false,
	height_meters_value: float = 0.0,
	wallet_coins_value: int = 0,
	run_earned_coins_value: int = 0
) -> void:
	visible = visible_value
	height_meters = height_meters_value
	wallet_coins = wallet_coins_value
	run_earned_coins = run_earned_coins_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(height_meters >= 0.0, "PauseMenuState height cannot be negative.")
	Validation.require_condition(wallet_coins >= 0, "PauseMenuState wallet coins cannot be negative.")
	Validation.require_condition(run_earned_coins >= 0, "PauseMenuState run-earned coins cannot be negative.")