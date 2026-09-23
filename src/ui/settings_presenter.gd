class_name SettingsPresenter
extends RefCounted

const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const SettingsStateScript = preload("res://src/ui/settings_state.gd")

func build_state(settings_snapshot: RefCounted, visible: bool) -> SettingsStateScript:
    Validation.require_condition(settings_snapshot != null, "SettingsPresenter requires an app settings snapshot.")
    Validation.require_condition(settings_snapshot is AppSettingsSnapshotScript, "SettingsPresenter requires an AppSettingsSnapshot implementation.")
    var typed_snapshot: AppSettingsSnapshotScript = settings_snapshot as AppSettingsSnapshotScript
    typed_snapshot.assert_valid()
    return SettingsStateScript.new(
        visible,
        typed_snapshot.audio_muted,
        typed_snapshot.master_volume_ratio,
        typed_snapshot.haptics_enabled,
        typed_snapshot.touch_split_ratio,
        typed_snapshot.touch_center_dead_zone_ratio,
        typed_snapshot.music_volume_ratio
    )