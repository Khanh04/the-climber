class_name PlayerPhysicsMode
extends RefCounted

const CONTROLLED_CLIMB: int = 0
const FALLING_RAGDOLL: int = 1

static func controlled_climb() -> int:
	return CONTROLLED_CLIMB

static func falling_ragdoll() -> int:
	return FALLING_RAGDOLL

static func is_valid(value: int) -> bool:
	match value:
		CONTROLLED_CLIMB:
			return true
		FALLING_RAGDOLL:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported player physics mode.")