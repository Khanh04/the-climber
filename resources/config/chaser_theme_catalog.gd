class_name ChaserThemeCatalog
extends Resource

const ChaserThemeScript = preload("res://resources/config/chaser_theme.gd")

@export var themes: Array[Resource] = []

func is_valid() -> bool:
	if themes.is_empty():
		return false

	var seen_theme_ids: Dictionary[StringName, bool] = {}
	for theme in themes:
		if theme == null or not theme is ChaserThemeScript:
			return false

		var typed_theme: ChaserThemeScript = theme as ChaserThemeScript
		if not typed_theme.is_valid() or seen_theme_ids.has(typed_theme.theme_id):
			return false

		seen_theme_ids[typed_theme.theme_id] = true

	return true

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not themes.is_empty(), "Chaser theme catalog requires at least one theme.")

	var seen_theme_ids: Dictionary[StringName, bool] = {}
	for theme in themes:
		Validation.require_condition(theme != null, "Chaser theme catalog cannot contain null themes.")
		Validation.require_condition(theme is ChaserThemeScript, "Chaser theme catalog requires ChaserTheme resources.")
		var typed_theme: ChaserThemeScript = theme as ChaserThemeScript
		typed_theme.assert_valid()
		Validation.require_condition(not seen_theme_ids.has(typed_theme.theme_id), "Chaser theme catalog theme ids must be unique.")
		seen_theme_ids[typed_theme.theme_id] = true

func get_required_theme_by_id(theme_id: StringName) -> ChaserThemeScript:
	Validation.require_condition(not theme_id.is_empty(), "Chaser theme catalog lookup requires a theme id.")
	assert_valid()

	for theme in themes:
		var typed_theme: ChaserThemeScript = theme as ChaserThemeScript
		if typed_theme.theme_id == theme_id:
			return typed_theme

	Validation.require_condition(false, "Chaser theme catalog is missing theme id %s." % String(theme_id))
	return null