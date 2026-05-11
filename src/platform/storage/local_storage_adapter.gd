class_name LocalStorageAdapter
extends RefCounted

func has_key(key: String) -> bool:
    Validation.require_condition(false, "LocalStorageAdapter.has_key must be implemented.")
    return false

func load_dictionary(key: String) -> Dictionary:
    Validation.require_condition(false, "LocalStorageAdapter.load_dictionary must be implemented.")
    return {}

func save_dictionary(key: String, value: Dictionary) -> void:
    Validation.require_condition(false, "LocalStorageAdapter.save_dictionary must be implemented.")

func delete_key(key: String) -> void:
    Validation.require_condition(false, "LocalStorageAdapter.delete_key must be implemented.")