class_name AppSettingsStorage
extends RefCounted

const AppSettingsSchemaScript = preload("res://src/platform/storage/app_settings_schema.gd")
const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")

var _local_storage: LocalStorageAdapterScript

func _init(local_storage: RefCounted) -> void:
    Validation.require_condition(local_storage != null, "AppSettingsStorage requires a local storage adapter.")
    Validation.require_condition(local_storage is LocalStorageAdapterScript, "AppSettingsStorage requires a local storage adapter implementation.")
    _local_storage = local_storage as LocalStorageAdapterScript

func has_snapshot() -> bool:
    return _local_storage.has_key(AppSettingsSchemaScript.SNAPSHOT_KEY)

func load_snapshot() -> AppSettingsSnapshotScript:
    Validation.require_condition(has_snapshot(), "App settings snapshot does not exist.")
    return AppSettingsSnapshotScript.from_dictionary(_local_storage.load_dictionary(AppSettingsSchemaScript.SNAPSHOT_KEY))

func save_snapshot(snapshot: RefCounted) -> void:
    Validation.require_condition(snapshot != null, "AppSettingsStorage requires an app settings snapshot instance.")
    Validation.require_condition(snapshot is AppSettingsSnapshotScript, "AppSettingsStorage requires an AppSettingsSnapshot instance.")
    var typed_snapshot: AppSettingsSnapshotScript = snapshot as AppSettingsSnapshotScript
    _local_storage.save_dictionary(AppSettingsSchemaScript.SNAPSHOT_KEY, typed_snapshot.to_dictionary())

func delete_snapshot() -> void:
    _local_storage.delete_key(AppSettingsSchemaScript.SNAPSHOT_KEY)