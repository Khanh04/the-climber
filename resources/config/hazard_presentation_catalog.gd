class_name HazardPresentationCatalog
extends Resource

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const HazardPresentationDefinitionScript = preload("res://resources/config/hazard_presentation_definition.gd")

@export var definitions: Array[Resource] = []

func is_valid() -> bool:
	if definitions.is_empty():
		return false

	var seen_kinds: Dictionary[int, bool] = {}
	for definition_resource in definitions:
		if definition_resource == null or not definition_resource is HazardPresentationDefinitionScript:
			return false
		var definition: HazardPresentationDefinitionScript = definition_resource as HazardPresentationDefinitionScript
		if not definition.is_valid() or seen_kinds.has(definition.hazard_kind):
			return false
		seen_kinds[definition.hazard_kind] = true

	for hazard_kind in GeneratedHazardKindScript.get_all_values():
		if not seen_kinds.has(hazard_kind):
			return false
	return true

func assert_valid() -> void:
	Validation.require_condition(not definitions.is_empty(), "Hazard presentation catalog requires definitions.")
	var seen_kinds: Dictionary[int, bool] = {}
	for definition_resource in definitions:
		Validation.require_condition(definition_resource is HazardPresentationDefinitionScript, "Hazard presentation catalog requires typed definitions.")
		var definition: HazardPresentationDefinitionScript = definition_resource as HazardPresentationDefinitionScript
		definition.assert_valid()
		Validation.require_condition(not seen_kinds.has(definition.hazard_kind), "Hazard presentation kinds must be unique.")
		seen_kinds[definition.hazard_kind] = true

	for hazard_kind in GeneratedHazardKindScript.get_all_values():
		Validation.require_condition(
			seen_kinds.has(hazard_kind),
			"Hazard presentation catalog requires %s." % GeneratedHazardKindScript.to_label(hazard_kind)
		)

func get_required_definition(hazard_kind: int) -> HazardPresentationDefinitionScript:
	GeneratedHazardKindScript.assert_valid(hazard_kind)
	for definition_resource in definitions:
		var definition: HazardPresentationDefinitionScript = definition_resource as HazardPresentationDefinitionScript
		if definition.hazard_kind == hazard_kind:
			return definition

	Validation.require_condition(false, "Missing presentation for hazard %s." % GeneratedHazardKindScript.to_label(hazard_kind))
	return null
