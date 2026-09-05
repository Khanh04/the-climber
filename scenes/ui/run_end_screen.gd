class_name RunEndScreen
extends Control

signal restart_requested
signal new_seed_run_requested
signal main_menu_requested
signal rewarded_continue_requested
signal post_run_coin_doubler_requested
signal store_requested

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunEndScreenStateScript = preload("res://src/ui/run_end_screen_state.gd")

@onready var _title_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label
@onready var _reason_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/ReasonLabel") as Label
@onready var _summary_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/SummaryLabel") as Label
@onready var _ad_feedback_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/AdFeedbackLabel") as Label
@onready var _rewarded_continue_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton") as Button
@onready var _post_run_coin_doubler_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/PostRunCoinDoublerButton") as Button
@onready var _store_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/StoreButton") as Button
@onready var _restart_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button
@onready var _new_seed_run_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/NewSeedRunButton") as Button
@onready var _main_menu_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/MainMenuButton") as Button

func _ready() -> void:
	_validate_required_nodes()
	var _rewarded_continue_connect_result: int = _rewarded_continue_button.connect(&"pressed", Callable(self, "_on_rewarded_continue_button_pressed"))
	var _post_run_coin_doubler_connect_result: int = _post_run_coin_doubler_button.connect(&"pressed", Callable(self, "_on_post_run_coin_doubler_button_pressed"))
	var _store_connect_result: int = _store_button.connect(&"pressed", Callable(self, "_on_store_button_pressed"))
	var _connect_result: int = _restart_button.connect(&"pressed", Callable(self, "_on_restart_button_pressed"))
	var _new_seed_run_connect_result: int = _new_seed_run_button.connect(&"pressed", Callable(self, "_on_new_seed_run_button_pressed"))
	var _main_menu_connect_result: int = _main_menu_button.connect(&"pressed", Callable(self, "_on_main_menu_button_pressed"))

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "RunEndScreen requires a state snapshot.")
	Validation.require_condition(state is RunEndScreenStateScript, "RunEndScreen requires a RunEndScreenState snapshot.")

	var typed_state: Object = state
	typed_state.call("assert_valid")

	var is_visible_state: bool = typed_state.get("visible")
	var is_rescue_offered_state: bool = typed_state.get("rescue_offered")
	var end_reason: int = typed_state.get("end_reason")
	var final_height_meters: float = typed_state.get("final_height_meters")
	var wallet_coins: int = typed_state.get("wallet_coins")
	var run_earned_coins: int = typed_state.get("run_earned_coins")
	var show_post_run_coin_doubler: bool = typed_state.get("show_post_run_coin_doubler")
	var show_rewarded_continue: bool = typed_state.get("show_rewarded_continue")
	var ad_feedback_message: String = typed_state.get("ad_feedback_message")

	visible = is_visible_state
	_ad_feedback_label.visible = not ad_feedback_message.is_empty()
	_ad_feedback_label.text = ad_feedback_message
	_rewarded_continue_button.visible = show_rewarded_continue
	_post_run_coin_doubler_button.visible = show_post_run_coin_doubler
	if not visible:
		return

	_title_label.text = "Rescue Offered" if is_rescue_offered_state else "Run Ended"
	_reason_label.text = "Reason: %s" % _format_end_reason(end_reason)
	_summary_label.text = "Height: %.1f m\nWallet Coins: %d\nRun Coins: %d" % [final_height_meters, wallet_coins, run_earned_coins]

	if is_rescue_offered_state:
		if show_rewarded_continue:
			_summary_label.text += "\nWatch an ad to continue this run once, or restart now."
		else:
			_summary_label.text += "\nRewarded continue is unavailable. Restart is available now."

func _on_rewarded_continue_button_pressed() -> void:
	rewarded_continue_requested.emit()

func _on_post_run_coin_doubler_button_pressed() -> void:
	post_run_coin_doubler_requested.emit()

func _on_store_button_pressed() -> void:
	store_requested.emit()

func _format_end_reason(reason: int) -> String:
	RunEndReasonScript.assert_valid(reason)

	match reason:
		RunEndReasonScript.Value.BOTTOM_SCREEN_FALL:
			return "Bottom-screen fall"
		RunEndReasonScript.Value.STAMINA_FALL:
			return "Stamina fall"
		RunEndReasonScript.Value.MISSED_GRIP_FALL:
			return "Missed grip fall"
		RunEndReasonScript.Value.CHASER_CONTACT:
			return "Chaser contact"
		RunEndReasonScript.Value.LETHAL_HAZARD:
			return "Lethal hazard"
		RunEndReasonScript.Value.ALREADY_RESCUED:
			return "Already rescued"
		_:
			Validation.require_condition(false, "Unsupported run end reason for RunEndScreen.")
			return ""

func _on_restart_button_pressed() -> void:
	restart_requested.emit()

func _on_new_seed_run_button_pressed() -> void:
	new_seed_run_requested.emit()

func _on_main_menu_button_pressed() -> void:
	main_menu_requested.emit()

func _validate_required_nodes() -> void:
	Validation.require_condition(_title_label != null, "RunEndScreen requires TitleLabel.")
	Validation.require_condition(_reason_label != null, "RunEndScreen requires ReasonLabel.")
	Validation.require_condition(_summary_label != null, "RunEndScreen requires SummaryLabel.")
	Validation.require_condition(_ad_feedback_label != null, "RunEndScreen requires AdFeedbackLabel.")
	Validation.require_condition(_rewarded_continue_button != null, "RunEndScreen requires RewardedContinueButton.")
	Validation.require_condition(_post_run_coin_doubler_button != null, "RunEndScreen requires PostRunCoinDoublerButton.")
	Validation.require_condition(_store_button != null, "RunEndScreen requires StoreButton.")
	Validation.require_condition(_restart_button != null, "RunEndScreen requires RestartButton.")
	Validation.require_condition(_new_seed_run_button != null, "RunEndScreen requires NewSeedRunButton.")
	Validation.require_condition(_main_menu_button != null, "RunEndScreen requires MainMenuButton.")
