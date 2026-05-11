class_name SubscriptionAdapter
extends RefCounted

const SubscriptionStatusScript = preload("res://src/platform/commerce/subscription_status.gd")

func get_status(subscription_product_id: String) -> int:
    Validation.require_condition(subscription_product_id != "", "Subscription product id cannot be empty.")
    Validation.require_condition(false, "SubscriptionAdapter.get_status must be implemented.")
    return SubscriptionStatusScript.Value.INACTIVE

func claim_daily_reward(subscription_product_id: String) -> bool:
    Validation.require_condition(subscription_product_id != "", "Subscription product id cannot be empty.")
    Validation.require_condition(false, "SubscriptionAdapter.claim_daily_reward must be implemented.")
    return false