class_name TutorialOverlayState
extends RefCounted

var prompt_text: String = ""
var visible: bool = false

func _init(prompt_text_value: String = "", visible_value: bool = false) -> void:
	prompt_text = prompt_text_value
	visible = visible_value

func assert_valid() -> void:
	Validation.require_condition(visible == (prompt_text != ""), "TutorialOverlayState visibility must match prompt text presence.")