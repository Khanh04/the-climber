class_name RunUiView
extends RefCounted

const RunEndScreenScript = preload("res://scenes/ui/run_end_screen.gd")
const RunEndScreenStateScript = preload("res://src/ui/run_end_screen_state.gd")
const RunHudScript = preload("res://scenes/ui/run_hud.gd")
const RunHudStateScript = preload("res://src/ui/run_hud_state.gd")

var _run_hud: Control
var _run_end_screen: Control

func _init(run_hud: Control, run_end_screen: Control) -> void:
	Validation.require_condition(run_hud != null, "RunUiView requires a RunHud control.")
	Validation.require_condition(run_hud is RunHudScript, "RunUiView requires a RunHud implementation.")
	Validation.require_condition(run_end_screen != null, "RunUiView requires a RunEndScreen control.")
	Validation.require_condition(run_end_screen is RunEndScreenScript, "RunUiView requires a RunEndScreen implementation.")

	_run_hud = run_hud
	_run_end_screen = run_end_screen

func apply_state_snapshots(hud_state: RefCounted, run_end_state: RefCounted) -> void:
	Validation.require_condition(hud_state != null, "RunUiView requires a HUD state snapshot.")
	Validation.require_condition(hud_state is RunHudStateScript, "RunUiView requires a RunHudState snapshot.")
	Validation.require_condition(run_end_state != null, "RunUiView requires a run-end screen state snapshot.")
	Validation.require_condition(run_end_state is RunEndScreenStateScript, "RunUiView requires a RunEndScreenState snapshot.")

	var typed_run_hud: Object = _run_hud
	var typed_run_end_screen: Object = _run_end_screen
	typed_run_hud.call("apply_state", hud_state)
	typed_run_end_screen.call("apply_state", run_end_state)