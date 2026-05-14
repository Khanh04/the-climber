class_name ChunkDifficultyBand
extends RefCounted

enum Value {
    EASY,
    BASELINE,
    CHALLENGE,
}

static func is_valid(value: int) -> bool:
    match value:
        Value.EASY:
            return true
        Value.BASELINE:
            return true
        Value.CHALLENGE:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported chunk difficulty band.")

static func to_label(value: int) -> String:
    match value:
        Value.EASY:
            return "EASY"
        Value.BASELINE:
            return "BASELINE"
        Value.CHALLENGE:
            return "CHALLENGE"
        _:
            Validation.require_condition(false, "ChunkDifficultyBand.to_label requires a supported difficulty band.")
            return ""