class_name HandholdSurfaceProfile
extends Resource

@export var stamina_drain_multiplier: float = 1.0

func is_valid() -> bool:
	return stamina_drain_multiplier > 0.0

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(stamina_drain_multiplier > 0.0, "Handhold surface profile stamina drain multiplier must be positive.")