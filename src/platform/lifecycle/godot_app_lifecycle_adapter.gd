class_name GodotAppLifecycleAdapter
extends "res://src/platform/lifecycle/app_lifecycle_adapter.gd"

const AppLifecycleEventScript = preload("res://src/platform/lifecycle/app_lifecycle_event.gd")
const AppLifecycleStateModelScript = preload("res://src/platform/lifecycle/app_lifecycle_state.gd")

var _current_state: int = AppLifecycleStateModelScript.Value.ACTIVE
var _pending_events: PackedInt32Array = PackedInt32Array()

func get_current_state() -> int:
	return _current_state

func consume_pending_events() -> PackedInt32Array:
	var events: PackedInt32Array = _pending_events.duplicate()
	_pending_events = PackedInt32Array()
	return events

func record_notification(notification_id: int) -> bool:
	match notification_id:
		MainLoop.NOTIFICATION_APPLICATION_PAUSED:
			_record_event(AppLifecycleEventScript.Value.PAUSED)
			return true
		MainLoop.NOTIFICATION_APPLICATION_RESUMED:
			_record_event(AppLifecycleEventScript.Value.RESUMED)
			return true
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			_record_event(AppLifecycleEventScript.Value.ENTERED_BACKGROUND)
			return true
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			_record_event(AppLifecycleEventScript.Value.ENTERED_FOREGROUND)
			return true
		_:
			return false

func _record_event(event_value: int) -> void:
	AppLifecycleEventScript.assert_valid(event_value)
	match event_value:
		AppLifecycleEventScript.Value.PAUSED:
			_current_state = AppLifecycleStateModelScript.Value.PAUSED
		AppLifecycleEventScript.Value.ENTERED_BACKGROUND:
			_current_state = AppLifecycleStateModelScript.Value.BACKGROUND
		AppLifecycleEventScript.Value.RESUMED:
			_current_state = AppLifecycleStateModelScript.Value.ACTIVE
		AppLifecycleEventScript.Value.ENTERED_FOREGROUND:
			_current_state = AppLifecycleStateModelScript.Value.ACTIVE
		AppLifecycleEventScript.Value.QUIT_REQUESTED:
			_current_state = AppLifecycleStateModelScript.Value.PAUSED
		_:
			Validation.require_condition(false, "GodotAppLifecycleAdapter requires a supported lifecycle event.")

	var _append_result: bool = _pending_events.append(event_value)