class_name StoreProduct
extends RefCounted

const StoreProductKindScript = preload("res://src/platform/commerce/store_product_kind.gd")

var product_id: String
var product_kind: int
var display_name: String

func _init(product_id_value: String, product_kind_value: int, display_name_value: String) -> void:
    product_id = product_id_value
    product_kind = product_kind_value
    display_name = display_name_value
    assert_valid()

func is_valid() -> bool:
    return product_id != "" and display_name != "" and StoreProductKindScript.is_valid(product_kind)

func assert_valid() -> void:
    Validation.require_condition(product_id != "", "Store product id cannot be empty.")
    Validation.require_condition(display_name != "", "Store product display name cannot be empty.")
    StoreProductKindScript.assert_valid(product_kind)