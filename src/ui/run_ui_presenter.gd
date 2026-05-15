class_name RunUiPresenter
extends RefCounted

const RunLoopCoordinatorScript = preload("res://src/gameplay/run/run_loop_coordinator.gd")
const RunEndScreenStateScript = preload("res://src/ui/run_end_screen_state.gd")
const RunHudStateScript = preload("res://src/ui/run_hud_state.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

var _run_loop_coordinator: RunLoopCoordinatorScript

func _init(run_loop_coordinator: RefCounted) -> void:
	Validation.require_condition(run_loop_coordinator != null, "RunUiPresenter requires a run-loop coordinator.")
	Validation.require_condition(run_loop_coordinator is RunLoopCoordinatorScript, "RunUiPresenter requires a RunLoopCoordinator implementation.")

	_run_loop_coordinator = run_loop_coordinator

func build_hud_state(run_session: RefCounted, stamina: RefCounted, wallet: RefCounted) -> RunHudStateScript:
	Validation.require_condition(run_session != null, "RunUiPresenter requires a run session to build HUD state.")
	Validation.require_condition(run_session is RunSessionScript, "RunUiPresenter requires a RunSession implementation for HUD state.")
	Validation.require_condition(stamina != null, "RunUiPresenter requires stamina runtime to build HUD state.")
	Validation.require_condition(stamina is StaminaRuntimeScript, "RunUiPresenter requires a StaminaRuntime implementation for HUD state.")
	Validation.require_condition(wallet != null, "RunUiPresenter requires a wallet to build HUD state.")
	Validation.require_condition(wallet is WalletScript, "RunUiPresenter requires a Wallet implementation for HUD state.")

	var typed_run_session: RunSessionScript = run_session
	var typed_stamina: StaminaRuntimeScript = stamina
	var typed_wallet: WalletScript = wallet
	var hud_state := RunHudStateScript.new(
		typed_run_session.get_height_meters(),
		typed_stamina.get_current_stamina_seconds(),
		typed_stamina.get_max_stamina_seconds(),
		typed_wallet.get_coins(),
		typed_run_session.get_run_earned_coins(),
		typed_run_session.get_state()
	)
	hud_state.assert_valid()
	return hud_state

func build_run_end_screen_state(run_session: RefCounted, wallet: RefCounted, show_post_run_coin_doubler: bool = false) -> RunEndScreenStateScript:
	return build_run_end_screen_state_with_ad_offers(run_session, wallet, show_post_run_coin_doubler, false)

func build_run_end_screen_state_with_ad_offers(
	run_session: RefCounted,
	wallet: RefCounted,
	show_post_run_coin_doubler: bool = false,
	show_rewarded_continue: bool = false,
	ad_feedback_message: String = ""
) -> RunEndScreenStateScript:
	Validation.require_condition(run_session != null, "RunUiPresenter requires a run session to build run-end state.")
	Validation.require_condition(run_session is RunSessionScript, "RunUiPresenter requires a RunSession implementation for run-end state.")
	Validation.require_condition(wallet != null, "RunUiPresenter requires a wallet to build run-end state.")
	Validation.require_condition(wallet is WalletScript, "RunUiPresenter requires a Wallet implementation for run-end state.")

	var typed_run_session: RunSessionScript = run_session
	var typed_wallet: WalletScript = wallet
	var run_state: int = typed_run_session.get_state()
	var has_end_reason: bool = typed_run_session.has_end_reason()
	var end_reason: int = -1
	if has_end_reason:
		end_reason = typed_run_session.get_end_reason()

	var run_end_state := RunEndScreenStateScript.new(
		_run_loop_coordinator.should_show_run_end_screen(run_state),
		_run_loop_coordinator.is_rescue_offered(run_state),
		typed_run_session.get_height_meters(),
		typed_wallet.get_coins(),
		typed_run_session.get_run_earned_coins(),
		has_end_reason,
		end_reason,
		show_post_run_coin_doubler
	)
	var run_end_state_object: Object = run_end_state
	run_end_state_object.set("show_rewarded_continue", show_rewarded_continue)
	run_end_state_object.set("ad_feedback_message", ad_feedback_message)
	run_end_state.assert_valid()
	return run_end_state