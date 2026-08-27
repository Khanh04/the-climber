class_name HazardPresentationDefinition
extends Resource

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const PresentationSceneValidatorScript = preload("res://resources/config/presentation_scene_validator.gd")

@export var hazard_kind: int = GeneratedHazardKindScript.Value.SPIKE_CLUSTER
@export var presentation_scene: PackedScene
@export var visual_offset: Vector2 = Vector2.ZERO
@export var visual_scale: Vector2 = Vector2.ONE
@export_range(-360.0, 360.0, 0.1, "radians_as_degrees") var visual_rotation_radians: float = 0.0
@export var orient_to_impulse: bool = false

func is_valid() -> bool:
	return GeneratedHazardKindScript.is_valid(hazard_kind) \
		and visual_scale.x != 0.0 \
		and visual_scale.y != 0.0 \
		and PresentationSceneValidatorScript.is_valid(presentation_scene)

func assert_valid() -> void:
	GeneratedHazardKindScript.assert_valid(hazard_kind)
	Validation.require_condition(visual_scale.x != 0.0 and visual_scale.y != 0.0, "Hazard presentation scale components cannot be zero.")
	PresentationSceneValidatorScript.assert_valid(
		presentation_scene,
		"Hazard %s" % GeneratedHazardKindScript.to_label(hazard_kind)
	)

func instantiate_presentation(impulse_vector_pixels: Vector2) -> Node2D:
	assert_valid()
	var instance: Node2D = presentation_scene.instantiate() as Node2D
	instance.position = visual_offset
	instance.scale = visual_scale
	instance.rotation = visual_rotation_radians
	if orient_to_impulse:
		Validation.require_condition(impulse_vector_pixels != Vector2.ZERO, "Oriented hazard presentation requires a non-zero impulse.")
		instance.rotation += impulse_vector_pixels.angle()
	return instance
