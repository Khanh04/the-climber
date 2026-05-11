class_name InMemoryLocalStorageAdapter
extends "res://src/platform/storage/local_storage_adapter.gd"

var _entries: Dictionary = {}

func has_key(key: String) -> bool:
    Validation.require_condition(key != "", "Local storage key cannot be empty.")
    return _entries.has(key)

func load_dictionary(key: String) -> Dictionary:
    Validation.require_condition(key != "", "Local storage key cannot be empty.")
    Validation.require_condition(_entries.has(key), "Local storage key does not exist.")

    var stored_value: Dictionary = _entries[key]
    return stored_value.duplicate(true)

func save_dictionary(key: String, value: Dictionary) -> void:
    Validation.require_condition(key != "", "Local storage key cannot be empty.")
    _entries[key] = value.duplicate(true)

func delete_key(key: String) -> void:
    Validation.require_condition(key != "", "Local storage key cannot be empty.")
    if _entries.has(key):
        var _was_removed: bool = _entries.erase(key)