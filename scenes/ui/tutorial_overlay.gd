class_name TutorialOverlay
extends Control

const TutorialOverlayStateScript = preload("res://src/ui/tutorial_overlay_state.gd")

@onready var _prompt_label: Label = get_node("Panel/PromptLabel") as Label

func _ready() -> void:
	_validate_required_nodes()

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "TutorialOverlay requires a state snapshot.")
	Validation.require_condition(state is TutorialOverlayStateScript, "TutorialOverlay requires a TutorialOverlayState snapshot.")
	var typed_state: TutorialOverlayStateScript = state as TutorialOverlayStateScript
	typed_state.assert_valid()
	_prompt_label.text = typed_state.prompt_text
	visible = typed_state.visible

func _validate_required_nodes() -> void:
	Validation.require_condition(_prompt_label != null, "TutorialOverlay requires PromptLabel.")