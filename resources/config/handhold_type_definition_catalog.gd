class_name HandholdTypeDefinitionCatalog
extends Resource

const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")

@export var definitions: Array[Resource] = []

func is_valid() -> bool:
	if definitions.is_empty():
		return false

	var seen_definition_ids: Dictionary[StringName, bool] = {}
	var seen_handhold_types: Dictionary[int, bool] = {}
	for definition_resource in definitions:
		if definition_resource == null or not definition_resource is HandholdTypeDefinitionScript:
			return false

		var typed_definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
		if not typed_definition.is_valid():
			return false

		if seen_definition_ids.has(typed_definition.definition_id):
			return false

		if seen_handhold_types.has(typed_definition.handhold_type):
			return false

		seen_definition_ids[typed_definition.definition_id] = true
		seen_handhold_types[typed_definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		if not seen_handhold_types.has(handhold_type):
			return false

	return true

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not definitions.is_empty(), "Handhold type definition catalog requires at least one definition.")

	var seen_definition_ids: Dictionary[StringName, bool] = {}
	var seen_handhold_types: Dictionary[int, bool] = {}
	for definition_resource in definitions:
		Validation.require_condition(definition_resource != null, "Handhold type definition catalog cannot contain null definitions.")
		Validation.require_condition(
			definition_resource is HandholdTypeDefinitionScript,
			"Handhold type definition catalog requires HandholdTypeDefinition resources."
		)
		var typed_definition: HandholdTypeDefinitionScript = definition_resource as HandholdTypeDefinitionScript
		typed_definition.assert_valid()
		Validation.require_condition(
			not seen_definition_ids.has(typed_definition.definition_id),
			"Handhold type definition catalog definition ids must be unique."
		)
		Validation.require_condition(
			not seen_handhold_types.has(typed_definition.handhold_type),
			"Handhold type definition catalog handhold types must be unique."
		)
		seen_definition_ids[typed_definition.definition_id] = true
		seen_handhold_types[typed_definition.handhold_type] = true

	for handhold_type in HandholdTypeScript.get_all_values():
		Validation.require_condition(
			seen_handhold_types.has(handhold_type),
			"Handhold type definition catalog requires a definition for %s." % HandholdTypeScript.to_label(handhold_type)
		)

func duplicate_definitions() -> Array[Resource]:
	assert_valid()

	var duplicated_definitions: Array[Resource] = []
	for definition_resource in definitions:
		var duplicated_definition_resource: Resource = definition_resource.duplicate(true)
		Validation.require_condition(
			duplicated_definition_resource is HandholdTypeDefinitionScript,
			"Handhold type definition catalog duplicates must remain typed HandholdTypeDefinition resources."
		)
		duplicated_definitions.append(duplicated_definition_resource)

	return duplicated_definitions