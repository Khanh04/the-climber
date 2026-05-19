class_name RunLaunchMode
extends RefCounted

enum Value {
	NORMAL,
	TUTORIAL
}

static func is_valid(mode: int) -> bool:
	match mode:
		Value.NORMAL:
			return true
		Value.TUTORIAL:
			return true
		_:
			return false

static func assert_valid(mode: int) -> void:
	Validation.require_condition(is_valid(mode), "Unsupported run launch mode.")