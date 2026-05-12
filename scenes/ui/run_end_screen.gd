class_name RunEndScreen
extends Control

signal restart_requested

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunEndScreenStateScript = preload("res://src/ui/run_end_screen_state.gd")

@onready var _title_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label
@onready var _reason_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/ReasonLabel") as Label
@onready var _summary_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/SummaryLabel") as Label
@onready var _restart_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button

func _ready() -> void:
	_validate_required_nodes()
	var _connect_result: int = _restart_button.connect(&"pressed", Callable(self, "_on_restart_button_pressed"))

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "RunEndScreen requires a state snapshot.")
	Validation.require_condition(state is RunEndScreenStateScript, "RunEndScreen requires a RunEndScreenState snapshot.")

	var typed_state: Object = state
	typed_state.call("assert_valid")

	var is_visible_state: bool = typed_state.get("visible")
	var is_rescue_offered_state: bool = typed_state.get("rescue_offered")
	var end_reason: int = typed_state.get("end_reason")
	var final_height_meters: float = typed_state.get("final_height_meters")
	var run_earned_coins: int = typed_state.get("run_earned_coins")

	visible = is_visible_state
	if not visible:
		return

	_title_label.text = "Rescue Offered" if is_rescue_offered_state else "Run Ended"
	_reason_label.text = "Reason: %s" % _format_end_reason(end_reason)
	_summary_label.text = "Height: %.1f m\nRun Coins: %d" % [final_height_meters, run_earned_coins]

	if is_rescue_offered_state:
		_summary_label.text += "\nRestart is available now. Rewarded continue arrives in Phase 9."

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

func _validate_required_nodes() -> void:
	Validation.require_condition(_title_label != null, "RunEndScreen requires TitleLabel.")
	Validation.require_condition(_reason_label != null, "RunEndScreen requires ReasonLabel.")
	Validation.require_condition(_summary_label != null, "RunEndScreen requires SummaryLabel.")
	Validation.require_condition(_restart_button != null, "RunEndScreen requires RestartButton.")