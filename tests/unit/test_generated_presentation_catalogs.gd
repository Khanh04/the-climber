extends GutTest

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const HazardPresentationDefinitionScript = preload("res://resources/config/hazard_presentation_definition.gd")
const HandholdPresentationDefinitionScript = preload("res://resources/config/handhold_presentation_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandholdPresentationCatalogResource = preload("res://resources/config/handhold_presentation_catalog.tres")
const HazardPresentationCatalogResource = preload("res://resources/config/hazard_presentation_catalog.tres")

func test_default_presentation_catalogs_cover_all_generated_types() -> void:
	assert_true(HandholdPresentationCatalogResource.is_valid())
	assert_true(HazardPresentationCatalogResource.is_valid())

	for handhold_type in HandholdTypeScript.get_all_values():
		var presentation: Node2D = HandholdPresentationCatalogResource.get_required_definition(handhold_type).instantiate_presentation()
		assert_not_null(presentation)
		presentation.free()

	for hazard_kind in GeneratedHazardKindScript.get_all_values():
		var impulse: Vector2 = Vector2.ZERO
		if hazard_kind == GeneratedHazardKindScript.Value.WIND_GUST \
			or hazard_kind == GeneratedHazardKindScript.Value.DOWNDRAFT \
			or hazard_kind == GeneratedHazardKindScript.Value.UPDRAFT:
			impulse = Vector2.RIGHT
		var presentation: Node2D = HazardPresentationCatalogResource.get_required_definition(hazard_kind).instantiate_presentation(impulse)
		assert_not_null(presentation)
		presentation.free()

func test_generated_presentation_scenes_are_physics_neutral() -> void:
	for handhold_type in HandholdTypeScript.get_all_values():
		var definition: HandholdPresentationDefinitionScript = HandholdPresentationCatalogResource.get_required_definition(handhold_type)
		assert_false(_contains_physics_node(definition.presentation_scene.instantiate()))

	for hazard_kind in GeneratedHazardKindScript.get_all_values():
		var definition: HazardPresentationDefinitionScript = HazardPresentationCatalogResource.get_required_definition(hazard_kind)
		assert_false(_contains_physics_node(definition.presentation_scene.instantiate()))

func _contains_physics_node(node: Node) -> bool:
	var contains_physics: bool = node is CollisionObject2D \
		or node is CollisionShape2D \
		or node is CollisionPolygon2D \
		or node is Joint2D \
		or node is CollisionObject3D \
		or node is CollisionShape3D \
		or node is Joint3D
	for child in node.get_children():
		contains_physics = contains_physics or _contains_physics_node(child)
	node.free()
	return contains_physics
