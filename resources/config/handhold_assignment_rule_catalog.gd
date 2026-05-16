class_name HandholdAssignmentRuleCatalog
extends Resource

const HandholdAssignmentRuleScript = preload("res://resources/config/handhold_assignment_rule.gd")

@export var rules: Array[Resource] = []

func is_valid() -> bool:
	if rules.is_empty():
		return false

	for rule_resource in rules:
		if rule_resource == null or not rule_resource is HandholdAssignmentRuleScript:
			return false

		var typed_rule: HandholdAssignmentRuleScript = rule_resource as HandholdAssignmentRuleScript
		if not typed_rule.is_valid():
			return false

	return true

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not rules.is_empty(), "Handhold assignment rule catalog requires at least one rule.")

	for rule_resource in rules:
		Validation.require_condition(rule_resource != null, "Handhold assignment rule catalog cannot contain null rules.")
		Validation.require_condition(
			rule_resource is HandholdAssignmentRuleScript,
			"Handhold assignment rule catalog requires HandholdAssignmentRule resources."
		)
		var typed_rule: HandholdAssignmentRuleScript = rule_resource as HandholdAssignmentRuleScript
		typed_rule.assert_valid()

func duplicate_rules() -> Array[Resource]:
	assert_valid()

	var duplicated_rules: Array[Resource] = []
	for rule_resource in rules:
		var duplicated_rule_resource: Resource = rule_resource.duplicate(true)
		Validation.require_condition(
			duplicated_rule_resource is HandholdAssignmentRuleScript,
			"Handhold assignment rule catalog duplicates must remain typed HandholdAssignmentRule resources."
		)
		duplicated_rules.append(duplicated_rule_resource)

	return duplicated_rules