class_name AudioSettingsAdapter
extends RefCounted

func apply_master_settings(master_volume_ratio: float, muted: bool) -> void:
    Validation.require_condition(master_volume_ratio >= 0.0 and master_volume_ratio <= 1.0, "AudioSettingsAdapter master volume ratio must be between 0 and 1.")
    Validation.require_condition(false, "AudioSettingsAdapter.apply_master_settings must be implemented.")

func get_master_volume_ratio() -> float:
    Validation.require_condition(false, "AudioSettingsAdapter.get_master_volume_ratio must be implemented.")
    return 1.0

func is_master_muted() -> bool:
    Validation.require_condition(false, "AudioSettingsAdapter.is_master_muted must be implemented.")
    return false
func apply_music_settings(music_volume_ratio: float) -> void:
    Validation.require_condition(music_volume_ratio >= 0.0 and music_volume_ratio <= 1.0, "Music volume must be between 0 and 1.")
    Validation.require_condition(false, "AudioSettingsAdapter.apply_music_settings must be implemented.")
