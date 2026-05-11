class_name AppLifecycleEvent
extends RefCounted

enum Value {
    PAUSED,
    RESUMED,
    ENTERED_BACKGROUND,
    ENTERED_FOREGROUND,
    QUIT_REQUESTED
}

static func is_valid(value: int) -> bool:
    match value:
        Value.PAUSED:
            return true
        Value.RESUMED:
            return true
        Value.ENTERED_BACKGROUND:
            return true
        Value.ENTERED_FOREGROUND:
            return true
        Value.QUIT_REQUESTED:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported app lifecycle event.")