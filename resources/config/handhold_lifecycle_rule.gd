class_name HandholdLifecycleRule
extends Resource

@export var break_after_attach_seconds: float = 0.0
@export var breaks_on_release: bool = false

func is_valid() -> bool:
	return break_after_attach_seconds >= 0.0

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(
		break_after_attach_seconds >= 0.0,
		"Handhold lifecycle rule break-after-attach seconds cannot be negative."
	)