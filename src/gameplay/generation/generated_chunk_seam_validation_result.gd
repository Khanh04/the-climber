class_name GeneratedChunkSeamValidationResult
extends RefCounted

var is_valid: bool
var failure_reason: String
var current_chunk_index: int
var next_chunk_index: int
var from_hold_id: StringName
var to_hold_id: StringName

func _init(
    is_valid_value: bool,
    failure_reason_value: String,
    current_chunk_index_value: int,
    next_chunk_index_value: int,
    from_hold_id_value: StringName,
    to_hold_id_value: StringName
) -> void:
    is_valid = is_valid_value
    failure_reason = failure_reason_value
    current_chunk_index = current_chunk_index_value
    next_chunk_index = next_chunk_index_value
    from_hold_id = from_hold_id_value
    to_hold_id = to_hold_id_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(current_chunk_index >= 0, "GeneratedChunkSeamValidationResult current chunk index cannot be negative.")
    Validation.require_condition(next_chunk_index >= 0, "GeneratedChunkSeamValidationResult next chunk index cannot be negative.")
    Validation.require_condition(
        next_chunk_index > current_chunk_index,
        "GeneratedChunkSeamValidationResult next chunk index must be greater than current chunk index."
    )
    Validation.require_condition(
        not String(from_hold_id).is_empty(),
        "GeneratedChunkSeamValidationResult requires a source hold id."
    )
    Validation.require_condition(
        not String(to_hold_id).is_empty(),
        "GeneratedChunkSeamValidationResult requires a target hold id."
    )

    if is_valid:
        Validation.require_condition(
            failure_reason == "",
            "GeneratedChunkSeamValidationResult cannot include a failure reason when valid."
        )
    else:
        Validation.require_condition(
            failure_reason != "",
            "GeneratedChunkSeamValidationResult requires a failure reason when invalid."
        )
