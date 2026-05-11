class_name Wallet
extends RefCounted

var _coins: int = 0

func _init(initial_coins: int = 0) -> void:
    Validation.require_condition(initial_coins >= 0, "Initial wallet coins cannot be negative.")
    _coins = initial_coins

func get_coins() -> int:
    return _coins

func grant_coins(amount: int) -> void:
    Validation.require_condition(amount > 0, "Coin grant amount must be positive.")
    _coins += amount

func spend_coins(amount: int) -> void:
    Validation.require_condition(amount > 0, "Coin spend amount must be positive.")
    Validation.require_condition(_coins >= amount, "Wallet cannot spend more coins than it contains.")
    _coins -= amount