class_name GeneratedHazardKind
extends RefCounted

enum Value {
	SPIKE_CLUSTER,
	WIND_GUST,
	DOWNDRAFT,
	UPDRAFT,
	FALLING_ROCK,
	PENDULUM_LOG,
	WANDERING_CRITTER,
	STARTLE_PUFF,
	BUG_SWARM,
}

static func is_valid(value: int) -> bool:
	match value:
		Value.SPIKE_CLUSTER:
			return true
		Value.WIND_GUST:
			return true
		Value.DOWNDRAFT:
			return true
		Value.UPDRAFT:
			return true
		Value.FALLING_ROCK:
			return true
		Value.PENDULUM_LOG:
			return true
		Value.WANDERING_CRITTER:
			return true
		Value.STARTLE_PUFF:
			return true
		Value.BUG_SWARM:
			return true
		_:
			return false

static func assert_valid(value: int) -> void:
	Validation.require_condition(is_valid(value), "Unsupported generated hazard kind.")

static func get_all_values() -> Array[int]:
	return [
		Value.SPIKE_CLUSTER,
		Value.WIND_GUST,
		Value.DOWNDRAFT,
		Value.UPDRAFT,
		Value.FALLING_ROCK,
		Value.PENDULUM_LOG,
		Value.WANDERING_CRITTER,
		Value.STARTLE_PUFF,
		Value.BUG_SWARM,
	]

static func to_label(value: int) -> String:
	assert_valid(value)
	match value:
		Value.SPIKE_CLUSTER:
			return "SPIKE_CLUSTER"
		Value.WIND_GUST:
			return "WIND_GUST"
		Value.DOWNDRAFT:
			return "DOWNDRAFT"
		Value.UPDRAFT:
			return "UPDRAFT"
		Value.FALLING_ROCK:
			return "FALLING_ROCK"
		Value.PENDULUM_LOG:
			return "PENDULUM_LOG"
		Value.WANDERING_CRITTER:
			return "WANDERING_CRITTER"
		Value.STARTLE_PUFF:
			return "STARTLE_PUFF"
		Value.BUG_SWARM:
			return "BUG_SWARM"
		_:
			Validation.require_condition(false, "Unsupported generated hazard kind label.")
			return ""
