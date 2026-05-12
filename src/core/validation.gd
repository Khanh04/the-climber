class_name Validation
extends RefCounted

static func require_condition(condition: bool, message: String) -> void:
	if condition:
		return

	push_error(message)
	assert(condition, message)
