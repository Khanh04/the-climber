class_name CosmeticPurchaseResult
extends RefCounted

const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")

var item_id: StringName
var outcome: int
var wallet_coins: int

func _init(
	item_id_value: StringName = &"body_default",
	outcome_value: int = CosmeticPurchaseOutcomeScript.Value.PURCHASED,
	wallet_coins_value: int = 0
) -> void:
	item_id = item_id_value
	outcome = outcome_value
	wallet_coins = wallet_coins_value
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not item_id.is_empty(), "CosmeticPurchaseResult item id cannot be empty.")
	CosmeticPurchaseOutcomeScript.assert_valid(outcome)
	Validation.require_condition(wallet_coins >= 0, "CosmeticPurchaseResult wallet coins cannot be negative.")