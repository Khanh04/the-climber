class_name GeneratedRouteValidationResult
extends RefCounted

var is_valid: bool
var failure_reason: String
var target_hold_id: StringName
var path_hold_ids: PackedStringArray

func _init(
    is_valid_value: bool,
    failure_reason_value: String,
    target_hold_id_value: StringName,
    path_hold_ids_value: PackedStringArray
) -> void:
    is_valid = is_valid_value
    failure_reason = failure_reason_value
    target_hold_id = target_hold_id_value
    path_hold_ids = path_hold_ids_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(
        not String(target_hold_id).is_empty(),
        "GeneratedRouteValidationResult requires a target hold id."
    )

    if is_valid:
        Validation.require_condition(
            failure_reason == "",
            "GeneratedRouteValidationResult cannot include a failure reason when valid."
        )
        Validation.require_condition(
            path_hold_ids.size() > 0,
            "GeneratedRouteValidationResult requires a non-empty path when valid."
        )
    else:
        Validation.require_condition(
            failure_reason != "",
            "GeneratedRouteValidationResult requires a failure reason when invalid."
        )

    for hold_id in path_hold_ids:
        Validation.require_condition(
            hold_id != "",
            "GeneratedRouteValidationResult path hold ids cannot contain empty entries."
        )
