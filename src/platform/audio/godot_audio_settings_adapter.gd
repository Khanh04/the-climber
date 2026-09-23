class_name GodotAudioSettingsAdapter
extends "res://src/platform/audio/audio_settings_adapter.gd"

const MASTER_BUS_NAME: String = "Master"
const MIN_VOLUME_DB: float = -80.0

func apply_master_settings(master_volume_ratio: float, muted: bool) -> void:
    Validation.require_condition(master_volume_ratio >= 0.0 and master_volume_ratio <= 1.0, "GodotAudioSettingsAdapter master volume ratio must be between 0 and 1.")
    var master_bus_index: int = _get_master_bus_index()
    AudioServer.set_bus_mute(master_bus_index, muted)
    AudioServer.set_bus_volume_db(master_bus_index, _volume_ratio_to_db(master_volume_ratio))

func get_master_volume_ratio() -> float:
    var master_bus_index: int = _get_master_bus_index()
    var volume_db: float = AudioServer.get_bus_volume_db(master_bus_index)
    if volume_db <= MIN_VOLUME_DB:
        return 0.0

    return db_to_linear(volume_db)

func is_master_muted() -> bool:
    return AudioServer.is_bus_mute(_get_master_bus_index())

func _get_master_bus_index() -> int:
    var master_bus_index: int = AudioServer.get_bus_index(MASTER_BUS_NAME)
    Validation.require_condition(master_bus_index >= 0, "GodotAudioSettingsAdapter requires the Master audio bus.")
    return master_bus_index

func _volume_ratio_to_db(master_volume_ratio: float) -> float:
    Validation.require_condition(master_volume_ratio >= 0.0 and master_volume_ratio <= 1.0, "GodotAudioSettingsAdapter master volume ratio must be between 0 and 1.")
    if is_zero_approx(master_volume_ratio):
        return MIN_VOLUME_DB

    return linear_to_db(master_volume_ratio)
func apply_music_settings(music_volume_ratio: float) -> void:
    Validation.require_condition(music_volume_ratio >= 0.0 and music_volume_ratio <= 1.0, "Music volume must be between 0 and 1.")
    var music_bus_index: int = AudioServer.get_bus_index("Music")
    Validation.require_condition(music_bus_index >= 0, "The default audio bus layout must contain Music.")
    AudioServer.set_bus_mute(music_bus_index, is_zero_approx(music_volume_ratio))
    AudioServer.set_bus_volume_db(music_bus_index, _volume_ratio_to_db(music_volume_ratio))
