class_name BestScoreStorage
extends RefCounted

const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")
const STORAGE_KEY: String = "best_score"
const KEY_HEIGHT_METERS: String = "height_meters"
var _storage: LocalStorageAdapterScript

func _init(storage: LocalStorageAdapterScript) -> void:
	Validation.require_condition(storage != null, "BestScoreStorage requires local storage.")
	_storage = storage

func get_best_height_meters() -> float:
	# Older saves have no record yet; keep their wallet and cosmetic data untouched.
	if not _storage.has_key(STORAGE_KEY):
		return 0.0
	var payload: Dictionary = _storage.load_dictionary(STORAGE_KEY)
	Validation.require_condition(payload.has(KEY_HEIGHT_METERS), "Best score is missing height_meters.")
	var raw_height: Variant = payload[KEY_HEIGHT_METERS]
	Validation.require_condition(raw_height is float or raw_height is int, "Best score height must be numeric.")
	var height: float = 0.0
	if raw_height is int:
		var integer_height: int = raw_height
		height = float(integer_height)
	else:
		var float_height: float = raw_height
		height = float_height
	Validation.require_condition(is_finite(height) and height >= 0.0, "Best score height must be finite and non-negative.")
	return height

func record_height(height_meters: float) -> void:
	Validation.require_condition(is_finite(height_meters) and height_meters >= 0.0, "Recorded best height must be finite and non-negative.")
	if height_meters > get_best_height_meters():
		_storage.save_dictionary(STORAGE_KEY, {KEY_HEIGHT_METERS: height_meters})
