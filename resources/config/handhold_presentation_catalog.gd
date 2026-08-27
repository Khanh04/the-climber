class_name HandholdPresentationCatalog
extends Resource

const HandholdPresentationDefinitionScript = preload("res://resources/config/handhold_presentation_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

@export var definitions: Array[Resource] = []

func is_valid() -> bool:
	if definitions.is_empty():
		return false

	var seen_types: Dictionary[int, bool] = {}
	for definition_resource in definitions:
		if definition_resource == null or not definition_resource is HandholdPresentationDefinitionScript:
			return false
		var definition: HandholdPresentationDefinitionScript = definition_resource as HandholdPresentationDefinitionScript
		if not definition.is_valid() or seen_types.has(definition.handhold_type):
			return false
		seen_types[definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		if not seen_types.has(handhold_type):
			return false
	return true

func assert_valid() -> void:
	Validation.require_condition(not definitions.is_empty(), "Handhold presentation catalog requires definitions.")
	var seen_types: Dictionary[int, bool] = {}
	for definition_resource in definitions:
		Validation.require_condition(definition_resource is HandholdPresentationDefinitionScript, "Handhold presentation catalog requires typed definitions.")
		var definition: HandholdPresentationDefinitionScript = definition_resource as HandholdPresentationDefinitionScript
		definition.assert_valid()
		Validation.require_condition(not seen_types.has(definition.handhold_type), "Handhold presentation types must be unique.")
		seen_types[definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		Validation.require_condition(
			seen_types.has(handhold_type),
			"Handhold presentation catalog requires %s." % HandholdTypeScript.to_label(handhold_type)
		)

func get_required_definition(handhold_type: int) -> HandholdPresentationDefinitionScript:
	HandholdTypeScript.assert_valid(handhold_type)
	for definition_resource in definitions:
		var definition: HandholdPresentationDefinitionScript = definition_resource as HandholdPresentationDefinitionScript
		if definition.handhold_type == handhold_type:
			return definition

	Validation.require_condition(false, "Missing presentation for handhold %s." % HandholdTypeScript.to_label(handhold_type))
	return null
