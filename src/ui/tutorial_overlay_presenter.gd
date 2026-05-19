class_name TutorialOverlayPresenter
extends RefCounted

const TutorialOverlayStateScript = preload("res://src/ui/tutorial_overlay_state.gd")

func build_state(prompt_text: String) -> TutorialOverlayStateScript:
	var tutorial_overlay_state: TutorialOverlayStateScript = TutorialOverlayStateScript.new(prompt_text, prompt_text != "")
	tutorial_overlay_state.assert_valid()
	return tutorial_overlay_state