extends GutTest

const AppSettingsSchemaScript = preload("res://src/platform/storage/app_settings_schema.gd")
const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const AppSettingsStorageScript = preload("res://src/platform/storage/app_settings_storage.gd")
const InMemoryLocalStorageAdapterScript = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const SettingsPresenterScript = preload("res://src/ui/settings_presenter.gd")
const SettingsStateScript = preload("res://src/ui/settings_state.gd")
const TouchInputSettingsScript = preload("res://src/gameplay/player/touch_input_settings.gd")

func test_default_app_settings_snapshot_is_valid() -> void:
    var snapshot := AppSettingsSnapshotScript.new()

    assert_true(snapshot.is_valid())
    assert_false(snapshot.audio_muted)
    assert_eq(snapshot.master_volume_ratio, 1.0)
    assert_true(snapshot.haptics_enabled)

func test_app_settings_snapshot_round_trips_dictionary_payload() -> void:
    var snapshot := AppSettingsSnapshotScript.new(
        AppSettingsSchemaScript.VERSION,
        true,
        0.45,
        false,
        0.60,
        0.08
    )
    var dictionary: Dictionary = snapshot.to_dictionary()
    var loaded_snapshot: AppSettingsSnapshotScript = AppSettingsSnapshotScript.from_dictionary(dictionary)
    var touch_settings: TouchInputSettingsScript = loaded_snapshot.to_touch_input_settings()

    assert_true(AppSettingsSnapshotScript.is_dictionary_valid(dictionary))
    assert_true(loaded_snapshot.audio_muted)
    assert_eq(loaded_snapshot.master_volume_ratio, 0.45)
    assert_false(loaded_snapshot.haptics_enabled)
    assert_eq(touch_settings.split_ratio, 0.60)
    assert_eq(touch_settings.center_dead_zone_ratio, 0.08)

func test_app_settings_snapshot_rejects_invalid_dictionary_payload() -> void:
    var dictionary: Dictionary = AppSettingsSnapshotScript.new().to_dictionary()
    dictionary[AppSettingsSchemaScript.KEY_MASTER_VOLUME_RATIO] = 1.5

    assert_false(AppSettingsSnapshotScript.is_dictionary_valid(dictionary))

func test_app_settings_storage_saves_and_loads_snapshot() -> void:
    var local_storage := InMemoryLocalStorageAdapterScript.new()
    var storage := AppSettingsStorageScript.new(local_storage)
    var snapshot := AppSettingsSnapshotScript.new(
        AppSettingsSchemaScript.VERSION,
        false,
        0.25,
        true,
        0.40,
        0.05
    )

    storage.save_snapshot(snapshot)
    var loaded_snapshot: AppSettingsSnapshotScript = storage.load_snapshot()

    assert_true(storage.has_snapshot())
    assert_eq(loaded_snapshot.master_volume_ratio, 0.25)
    assert_eq(loaded_snapshot.touch_split_ratio, 0.40)

func test_settings_presenter_builds_state_from_snapshot() -> void:
    var presenter := SettingsPresenterScript.new()
    var snapshot := AppSettingsSnapshotScript.new(
        AppSettingsSchemaScript.VERSION,
        true,
        0.70,
        false,
        0.55,
        0.04
    )

    var state: SettingsStateScript = presenter.build_state(snapshot, true)

    assert_true(state.visible)
    assert_true(state.audio_muted)
    assert_eq(state.master_volume_ratio, 0.70)
    assert_false(state.haptics_enabled)
    assert_eq(state.touch_split_ratio, 0.55)
    assert_eq(state.touch_center_dead_zone_ratio, 0.04)

func test_touch_input_settings_rejects_out_of_range_values() -> void:
    assert_true(TouchInputSettingsScript.are_values_valid(0.50, 0.0))
    assert_false(TouchInputSettingsScript.are_values_valid(0.20, 0.0))
    assert_false(TouchInputSettingsScript.are_values_valid(0.50, 0.40))