class_name RunEndScreenState
extends RefCounted

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")

var visible: bool = false
var rescue_offered: bool = false
var final_height_meters: float = 0.0
var wallet_coins: int = 0
var run_earned_coins: int = 0
var has_end_reason: bool = false
var end_reason: int = -1
var show_post_run_coin_doubler: bool = false

func _init(
	visible_value: bool = false,
	rescue_offered_value: bool = false,
	final_height_meters_value: float = 0.0,
	wallet_coins_value: int = 0,
	run_earned_coins_value: int = 0,
	has_end_reason_value: bool = false,
	end_reason_value: int = -1,
	show_post_run_coin_doubler_value: bool = false
) -> void:
	visible = visible_value
	rescue_offered = rescue_offered_value
	final_height_meters = final_height_meters_value
	wallet_coins = wallet_coins_value
	run_earned_coins = run_earned_coins_value
	has_end_reason = has_end_reason_value
	end_reason = end_reason_value
	show_post_run_coin_doubler = show_post_run_coin_doubler_value

func assert_valid() -> void:
	Validation.require_condition(final_height_meters >= 0.0, "RunEndScreenState final height cannot be negative.")
	Validation.require_condition(wallet_coins >= 0, "RunEndScreenState wallet coins cannot be negative.")
	Validation.require_condition(run_earned_coins >= 0, "RunEndScreenState run-earned coins cannot be negative.")
	Validation.require_condition(not rescue_offered or visible, "RunEndScreenState rescue-offered UI must also be visible.")
	Validation.require_condition(not show_post_run_coin_doubler or visible, "RunEndScreenState post-run doubler offer must also be visible.")
	Validation.require_condition(not show_post_run_coin_doubler or not rescue_offered, "RunEndScreenState cannot show the post-run doubler while rescue is offered.")
	Validation.require_condition(not show_post_run_coin_doubler or run_earned_coins > 0, "RunEndScreenState post-run doubler requires positive run-earned coins.")

	if has_end_reason:
		RunEndReasonScript.assert_valid(end_reason)
	else:
		Validation.require_condition(end_reason == -1, "RunEndScreenState without an end reason must use the sentinel value.")

	if visible:
		Validation.require_condition(has_end_reason, "RunEndScreenState requires an end reason when visible.")