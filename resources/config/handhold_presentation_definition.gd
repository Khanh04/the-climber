class_name HandholdPresentationDefinition
extends Resource

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const PresentationSceneValidatorScript = preload("res://resources/config/presentation_scene_validator.gd")

@export var handhold_type: int = HandholdTypeScript.Value.NORMAL
@export var presentation_scene: PackedScene
@export var visual_offset: Vector2 = Vector2.ZERO
@export var visual_scale: Vector2 = Vector2.ONE
@export_range(-360.0, 360.0, 0.1, "radians_as_degrees") var visual_rotation_radians: float = 0.0

func is_valid() -> bool:
	return HandholdTypeScript.is_valid(handhold_type) \
		and visual_scale.x != 0.0 \
		and visual_scale.y != 0.0 \
		and PresentationSceneValidatorScript.is_valid(presentation_scene)

func assert_valid() -> void:
	HandholdTypeScript.assert_valid(handhold_type)
	Validation.require_condition(visual_scale.x != 0.0 and visual_scale.y != 0.0, "Handhold presentation scale components cannot be zero.")
	PresentationSceneValidatorScript.assert_valid(
		presentation_scene,
		"Handhold %s" % HandholdTypeScript.to_label(handhold_type)
	)

func instantiate_presentation() -> Node2D:
	assert_valid()
	var instance: Node2D = presentation_scene.instantiate() as Node2D
	instance.position = visual_offset
	instance.scale = visual_scale
	instance.rotation = visual_rotation_radians
	return instance
