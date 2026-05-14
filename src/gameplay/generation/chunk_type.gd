class_name ChunkType
extends RefCounted

enum Value {
    LADDER,
    ZIGZAG,
    WIDE_TRAVERSE,
    SPARSE_REACH,
    DENSE_RECOVERY,
    FORK,
    RISK_LANE,
    SWING_GAP,
}

static func is_valid(value: int) -> bool:
    match value:
        Value.LADDER:
            return true
        Value.ZIGZAG:
            return true
        Value.WIDE_TRAVERSE:
            return true
        Value.SPARSE_REACH:
            return true
        Value.DENSE_RECOVERY:
            return true
        Value.FORK:
            return true
        Value.RISK_LANE:
            return true
        Value.SWING_GAP:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported chunk type.")

static func to_label(value: int) -> String:
    match value:
        Value.LADDER:
            return "LADDER"
        Value.ZIGZAG:
            return "ZIGZAG"
        Value.WIDE_TRAVERSE:
            return "WIDE_TRAVERSE"
        Value.SPARSE_REACH:
            return "SPARSE_REACH"
        Value.DENSE_RECOVERY:
            return "DENSE_RECOVERY"
        Value.FORK:
            return "FORK"
        Value.RISK_LANE:
            return "RISK_LANE"
        Value.SWING_GAP:
            return "SWING_GAP"
        _:
            Validation.require_condition(false, "ChunkType.to_label requires a supported chunk type.")
            return ""