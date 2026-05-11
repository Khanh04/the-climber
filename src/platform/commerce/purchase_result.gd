class_name PurchaseResult
extends RefCounted

const PurchaseOutcomeScript = preload("res://src/platform/commerce/purchase_outcome.gd")

var product_id: String
var outcome: int

func _init(product_id_value: String, outcome_value: int) -> void:
    product_id = product_id_value
    outcome = outcome_value
    assert_valid()

func is_valid() -> bool:
    return product_id != "" and PurchaseOutcomeScript.is_valid(outcome)

func assert_valid() -> void:
    Validation.require_condition(product_id != "", "Purchase result product id cannot be empty.")
    PurchaseOutcomeScript.assert_valid(outcome)