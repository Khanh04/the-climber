extends GutTest

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunEndScreenStateScript = preload("res://src/ui/run_end_screen_state.gd")
const RunHudStateScript = preload("res://src/ui/run_hud_state.gd")
const RunLoopCoordinatorScript = preload("res://src/gameplay/run/run_loop_coordinator.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const RunUiPresenterScript = preload("res://src/ui/run_ui_presenter.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

func test_build_hud_state_captures_run_session_and_stamina_snapshot() -> void:
	var presenter: RunUiPresenterScript = RunUiPresenterScript.new(RunLoopCoordinatorScript.new())
	var run_session: RefCounted = RunSessionScript.new()
	var stamina: RefCounted = StaminaRuntimeScript.new(StaminaTuningScript.new())
	var wallet: RefCounted = WalletScript.new(7)

	run_session.call("start_run")
	run_session.call("record_height", 12.5)
	run_session.call("add_run_earned_coins", 3)
	var _depleted_now: bool = stamina.call("advance", 1, 2.0)

	var hud_state: RunHudStateScript = presenter.build_hud_state(run_session, stamina, wallet)

	assert_eq(hud_state.height_meters, 12.5)
	assert_eq(hud_state.current_stamina_seconds, 6.0)
	assert_eq(hud_state.max_stamina_seconds, 8.0)
	assert_eq(hud_state.wallet_coins, 7)
	assert_eq(hud_state.run_earned_coins, 3)
	assert_eq(hud_state.run_state, RunStateScript.Value.CLIMBING)

func test_build_run_end_screen_state_hides_screen_for_active_run() -> void:
	var presenter: RunUiPresenterScript = RunUiPresenterScript.new(RunLoopCoordinatorScript.new())
	var run_session: RefCounted = RunSessionScript.new()
	var wallet: RefCounted = WalletScript.new(5)

	run_session.call("start_run")

	var run_end_state: RunEndScreenStateScript = presenter.build_run_end_screen_state(run_session, wallet)

	assert_false(run_end_state.visible)
	assert_false(run_end_state.rescue_offered)
	assert_false(run_end_state.has_end_reason)
	assert_false(run_end_state.show_post_run_coin_doubler)
	assert_false(_get_show_rewarded_continue(run_end_state))
	assert_eq(run_end_state.wallet_coins, 5)

func test_build_run_end_screen_state_marks_rescue_offer_and_end_reason() -> void:
	var presenter: RunUiPresenterScript = RunUiPresenterScript.new(RunLoopCoordinatorScript.new())
	var run_session: RefCounted = RunSessionScript.new()
	var wallet: RefCounted = WalletScript.new(11)

	run_session.call("start_run")
	run_session.call("begin_fall")
	run_session.call("resolve_fall", RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)

	var run_end_state: RunEndScreenStateScript = presenter.build_run_end_screen_state(run_session, wallet)

	assert_true(run_end_state.visible)
	assert_true(run_end_state.rescue_offered)
	assert_true(run_end_state.has_end_reason)
	assert_false(run_end_state.show_post_run_coin_doubler)
	assert_false(_get_show_rewarded_continue(run_end_state))
	assert_eq(run_end_state.wallet_coins, 11)
	assert_eq(run_end_state.end_reason, RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)

func test_build_run_end_screen_state_surfaces_rewarded_continue_offer() -> void:
	var presenter: RunUiPresenterScript = RunUiPresenterScript.new(RunLoopCoordinatorScript.new())
	var run_session: RefCounted = RunSessionScript.new()
	var wallet: RefCounted = WalletScript.new(13)

	run_session.call("start_run")
	run_session.call("begin_fall")
	run_session.call("resolve_fall", RunEndReasonScript.Value.MISSED_GRIP_FALL)

	var run_end_state: RunEndScreenStateScript = presenter.build_run_end_screen_state_with_ad_offers(run_session, wallet, false, true)

	assert_true(run_end_state.visible)
	assert_true(run_end_state.rescue_offered)
	assert_false(run_end_state.show_post_run_coin_doubler)
	assert_true(_get_show_rewarded_continue(run_end_state))
	assert_eq(run_end_state.end_reason, RunEndReasonScript.Value.MISSED_GRIP_FALL)

func test_build_run_end_screen_state_surfaces_post_run_coin_doubler_offer() -> void:
	var presenter: RunUiPresenterScript = RunUiPresenterScript.new(RunLoopCoordinatorScript.new())
	var run_session: RefCounted = RunSessionScript.new()
	var wallet: RefCounted = WalletScript.new(11)

	run_session.call("start_run")
	run_session.call("add_run_earned_coins", 4)
	run_session.call("end_run", RunEndReasonScript.Value.CHASER_CONTACT)

	var run_end_state: RunEndScreenStateScript = presenter.build_run_end_screen_state(run_session, wallet, true)

	assert_true(run_end_state.visible)
	assert_false(run_end_state.rescue_offered)
	assert_true(run_end_state.has_end_reason)
	assert_true(run_end_state.show_post_run_coin_doubler)
	assert_false(_get_show_rewarded_continue(run_end_state))
	assert_eq(run_end_state.run_earned_coins, 4)
	assert_eq(run_end_state.end_reason, RunEndReasonScript.Value.CHASER_CONTACT)

func test_build_run_end_screen_state_surfaces_ad_feedback_message() -> void:
	var presenter: RunUiPresenterScript = RunUiPresenterScript.new(RunLoopCoordinatorScript.new())
	var run_session: RefCounted = RunSessionScript.new()
	var wallet: RefCounted = WalletScript.new(13)

	run_session.call("start_run")
	run_session.call("begin_fall")
	run_session.call("resolve_fall", RunEndReasonScript.Value.MISSED_GRIP_FALL)

	var run_end_state: RunEndScreenStateScript = presenter.build_run_end_screen_state_with_ad_offers(
		run_session, wallet, false, true, "Ad cancelled — you can try again."
	)

	assert_true(_get_show_rewarded_continue(run_end_state))
	var raw_message: Variant = run_end_state.get("ad_feedback_message")
	assert_true(raw_message is String)
	var message: String = raw_message
	assert_eq(message, "Ad cancelled — you can try again.")

func _get_show_rewarded_continue(run_end_state: RunEndScreenStateScript) -> bool:
	var raw_show_rewarded_continue: Variant = run_end_state.get("show_rewarded_continue")
	assert_true(raw_show_rewarded_continue is bool)
	var show_rewarded_continue: bool = raw_show_rewarded_continue
	return show_rewarded_continue