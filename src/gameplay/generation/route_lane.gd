class_name RouteLane
extends RefCounted

const RouteBranchSideScript = preload("res://src/gameplay/generation/route_branch_side.gd")

enum Value {
	OUTER_LEFT,
	INNER_LEFT,
	CENTER,
	INNER_RIGHT,
	OUTER_RIGHT,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.OUTER_LEFT:
			return true
		Value.INNER_LEFT:
			return true
		Value.CENTER:
			return true
		Value.INNER_RIGHT:
			return true
		Value.OUTER_RIGHT:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported route lane.")

static func get_all_values() -> Array[int]:
	return [
		Value.OUTER_LEFT,
		Value.INNER_LEFT,
		Value.CENTER,
		Value.INNER_RIGHT,
		Value.OUTER_RIGHT,
	]

static func to_offset(value: int) -> int:
	match value:
		Value.OUTER_LEFT:
			return -2
		Value.INNER_LEFT:
			return -1
		Value.CENTER:
			return 0
		Value.INNER_RIGHT:
			return 1
		Value.OUTER_RIGHT:
			return 2
		_:
			Validation.require_condition(false, "RouteLane.to_offset requires a supported lane.")
			return 0

static func is_outer(value: int) -> bool:
	assert_valid(value)
	return value == Value.OUTER_LEFT or value == Value.OUTER_RIGHT

static func to_branch_side(value: int) -> int:
	match value:
		Value.OUTER_LEFT:
			return RouteBranchSideScript.Value.LEFT
		Value.INNER_LEFT:
			return RouteBranchSideScript.Value.LEFT
		Value.CENTER:
			return RouteBranchSideScript.Value.NONE
		Value.INNER_RIGHT:
			return RouteBranchSideScript.Value.RIGHT
		Value.OUTER_RIGHT:
			return RouteBranchSideScript.Value.RIGHT
		_:
			Validation.require_condition(false, "RouteLane.to_branch_side requires a supported lane.")
			return RouteBranchSideScript.Value.NONE

static func to_label(value: int) -> String:
	match value:
		Value.OUTER_LEFT:
			return "OUTER_LEFT"
		Value.INNER_LEFT:
			return "INNER_LEFT"
		Value.CENTER:
			return "CENTER"
		Value.INNER_RIGHT:
			return "INNER_RIGHT"
		Value.OUTER_RIGHT:
			return "OUTER_RIGHT"
		_:
			Validation.require_condition(false, "RouteLane.to_label requires a supported lane.")
			return ""