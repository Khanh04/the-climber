class_name HapticsAdapterFactory
extends RefCounted

const GodotHapticsAdapterScript = preload("res://src/platform/haptics/godot_haptics_adapter.gd")
const HapticsAdapterScript = preload("res://src/platform/haptics/haptics_adapter.gd")
const UnavailableHapticsAdapterScript = preload("res://src/platform/haptics/unavailable_haptics_adapter.gd")

static func create_default() -> HapticsAdapterScript:
    return create_for_runtime(DisplayServer.get_name(), OS.get_name())

static func create_for_runtime(display_server_name: String, os_name: String) -> HapticsAdapterScript:
    Validation.require_condition(not display_server_name.is_empty(), "HapticsAdapterFactory requires a display server name.")
    Validation.require_condition(not os_name.is_empty(), "HapticsAdapterFactory requires an OS name.")
    if os_name == "Android":
        return GodotHapticsAdapterScript.new()

    return UnavailableHapticsAdapterScript.new()