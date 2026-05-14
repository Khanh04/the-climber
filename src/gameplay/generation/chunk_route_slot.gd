class_name ChunkRouteSlot
extends RefCounted

enum Value {
    OPENER,
    BASELINE,
    SKILL,
    RECOVERY,
    RISK,
    PRESSURE,
}

static func is_valid(value: int) -> bool:
    match value:
        Value.OPENER:
            return true
        Value.BASELINE:
            return true
        Value.SKILL:
            return true
        Value.RECOVERY:
            return true
        Value.RISK:
            return true
        Value.PRESSURE:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported chunk route slot.")

static func to_label(value: int) -> String:
    match value:
        Value.OPENER:
            return "OPENER"
        Value.BASELINE:
            return "BASELINE"
        Value.SKILL:
            return "SKILL"
        Value.RECOVERY:
            return "RECOVERY"
        Value.RISK:
            return "RISK"
        Value.PRESSURE:
            return "PRESSURE"
        _:
            Validation.require_condition(false, "ChunkRouteSlot.to_label requires a supported route slot.")
            return ""