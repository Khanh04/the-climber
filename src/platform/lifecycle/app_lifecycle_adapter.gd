class_name AppLifecycleAdapter
extends RefCounted

const AppLifecycleStateScript = preload("res://src/platform/lifecycle/app_lifecycle_state.gd")

func get_current_state() -> int:
    Validation.require_condition(false, "AppLifecycleAdapter.get_current_state must be implemented.")
    return AppLifecycleStateScript.Value.ACTIVE

func consume_pending_events() -> PackedInt32Array:
    Validation.require_condition(false, "AppLifecycleAdapter.consume_pending_events must be implemented.")
    return PackedInt32Array()