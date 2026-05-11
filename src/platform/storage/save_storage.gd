class_name SaveStorage
extends RefCounted

const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")

var _local_storage: LocalStorageAdapterScript

func _init(local_storage: RefCounted) -> void:
    Validation.require_condition(local_storage != null, "SaveStorage requires a local storage adapter.")
    Validation.require_condition(local_storage is LocalStorageAdapterScript, "SaveStorage requires a local storage adapter implementation.")
    _local_storage = local_storage

func has_snapshot() -> bool:
    return _local_storage.has_key(SaveSchemaScript.SNAPSHOT_KEY)

func load_snapshot() -> SaveSnapshotScript:
    Validation.require_condition(has_snapshot(), "Save snapshot does not exist.")
    return SaveSnapshotScript.from_dictionary(_local_storage.load_dictionary(SaveSchemaScript.SNAPSHOT_KEY))

func save_snapshot(snapshot: RefCounted) -> void:
    Validation.require_condition(snapshot != null, "SaveStorage requires a save snapshot instance.")
    Validation.require_condition(snapshot is SaveSnapshotScript, "SaveStorage requires a save snapshot instance.")

    var typed_snapshot: SaveSnapshotScript = snapshot
    _local_storage.save_dictionary(SaveSchemaScript.SNAPSHOT_KEY, typed_snapshot.to_dictionary())

func delete_snapshot() -> void:
    _local_storage.delete_key(SaveSchemaScript.SNAPSHOT_KEY)