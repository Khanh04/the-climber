class_name PurchaseAdapter
extends RefCounted

const PurchaseOutcomeScript = preload("res://src/platform/commerce/purchase_outcome.gd")
const PurchaseResultScript = preload("res://src/platform/commerce/purchase_result.gd")
const StoreProductScript = preload("res://src/platform/commerce/store_product.gd")

func is_product_available(product: RefCounted) -> bool:
    Validation.require_condition(product != null, "PurchaseAdapter requires a store product.")
    Validation.require_condition(product is StoreProductScript, "PurchaseAdapter requires a store product instance.")
    Validation.require_condition(false, "PurchaseAdapter.is_product_available must be implemented.")
    return false

func purchase(product: RefCounted) -> RefCounted:
    Validation.require_condition(product != null, "PurchaseAdapter requires a store product.")
    Validation.require_condition(product is StoreProductScript, "PurchaseAdapter requires a store product instance.")
    Validation.require_condition(false, "PurchaseAdapter.purchase must be implemented.")

    var typed_product: StoreProductScript = product
    return PurchaseResultScript.new(typed_product.product_id, PurchaseOutcomeScript.Value.UNAVAILABLE)

func restore_purchase_ids() -> PackedStringArray:
    Validation.require_condition(false, "PurchaseAdapter.restore_purchase_ids must be implemented.")
    return PackedStringArray()