class_name StoreProductKind
extends RefCounted

enum Value {
    COIN_BUNDLE,
    SUPPORTER_SUBSCRIPTION,
    COSMETIC_UNLOCK,
    CONSUMABLE
}

static func is_valid(value: int) -> bool:
    match value:
        Value.COIN_BUNDLE:
            return true
        Value.SUPPORTER_SUBSCRIPTION:
            return true
        Value.COSMETIC_UNLOCK:
            return true
        Value.CONSUMABLE:
            return true
        _:
            return false

static func assert_valid(value: int) -> void:
    Validation.require_condition(is_valid(value), "Unsupported store product kind.")