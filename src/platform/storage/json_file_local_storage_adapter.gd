class_name JsonFileLocalStorageAdapter
extends "res://src/platform/storage/local_storage_adapter.gd"

var _file_path: String

func _init(file_path: String = "user://save_storage.json") -> void:
	Validation.require_condition(not file_path.is_empty(), "JsonFileLocalStorageAdapter file path cannot be empty.")
	Validation.require_condition(file_path.begins_with("user://"), "JsonFileLocalStorageAdapter file path must use user://.")
	_file_path = file_path

func has_key(key: String) -> bool:
	Validation.require_condition(not key.is_empty(), "Local storage key cannot be empty.")
	var entries: Dictionary = _load_entries(false)
	return entries.has(key)

func load_dictionary(key: String) -> Dictionary:
	Validation.require_condition(not key.is_empty(), "Local storage key cannot be empty.")
	var entries: Dictionary = _load_entries(true)
	Validation.require_condition(entries.has(key), "Local storage key does not exist.")
	var raw_value: Variant = entries[key]
	Validation.require_condition(raw_value is Dictionary, "Local storage entry must be a dictionary.")
	var stored_value: Dictionary = raw_value
	return stored_value.duplicate(true)

func save_dictionary(key: String, value: Dictionary) -> void:
	Validation.require_condition(not key.is_empty(), "Local storage key cannot be empty.")
	var entries: Dictionary = _load_entries(false)
	entries[key] = value.duplicate(true)
	_write_entries(entries)

func delete_key(key: String) -> void:
	Validation.require_condition(not key.is_empty(), "Local storage key cannot be empty.")
	var entries: Dictionary = _load_entries(false)
	if entries.has(key):
		var _was_removed: bool = entries.erase(key)
		_write_entries(entries)

func _load_entries(require_existing_file: bool) -> Dictionary:
	if not FileAccess.file_exists(_file_path):
		Validation.require_condition(not require_existing_file, "Local storage file does not exist.")
		return {}

	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	Validation.require_condition(file != null, "JsonFileLocalStorageAdapter could not open local storage file for reading.")
	var raw_contents: String = file.get_as_text()
	Validation.require_condition(not raw_contents.is_empty(), "Local storage file cannot be empty.")

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(raw_contents)
	Validation.require_condition(parse_result == OK, "Local storage file contains invalid JSON.")
	Validation.require_condition(json.data is Dictionary, "Local storage file must contain a dictionary root.")
	var raw_entries: Dictionary = json.data
	_assert_entries_valid(raw_entries)
	return raw_entries

func _write_entries(entries: Dictionary) -> void:
	_assert_entries_valid(entries)
	var global_dir_path: String = ProjectSettings.globalize_path(_file_path.get_base_dir())
	var ensure_dir_result: int = DirAccess.make_dir_recursive_absolute(global_dir_path)
	Validation.require_condition(ensure_dir_result == OK, "JsonFileLocalStorageAdapter could not create the local storage directory.")

	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	Validation.require_condition(file != null, "JsonFileLocalStorageAdapter could not open local storage file for writing.")
	var _store_result: bool = file.store_string(JSON.stringify(entries))

func _assert_entries_valid(entries: Dictionary) -> void:
	for raw_key: Variant in entries.keys():
		Validation.require_condition(raw_key is String or raw_key is StringName, "Local storage keys must be strings.")
		var key_string: String = _key_string_from_variant(raw_key)
		Validation.require_condition(not key_string.is_empty(), "Local storage keys cannot be empty.")
		Validation.require_condition(entries[raw_key] is Dictionary, "Local storage values must be dictionaries.")

func _key_string_from_variant(raw_key: Variant) -> String:
	if raw_key is String:
		var raw_key_string: String = raw_key
		return raw_key_string

	var raw_key_name: StringName = raw_key
	return String(raw_key_name)