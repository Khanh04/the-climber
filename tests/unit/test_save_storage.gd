extends GutTest

const InMemoryLocalStorageAdapterScript = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")

func test_save_snapshot_round_trips_through_local_storage() -> void:
    var local_storage: RefCounted = InMemoryLocalStorageAdapterScript.new()
    var save_storage = SaveStorageScript.new(local_storage)
    var snapshot: RefCounted = SaveSnapshotScript.new(42)

    save_storage.save_snapshot(snapshot)

    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, 42)

func test_save_snapshot_dictionary_validation_rejects_unsupported_schema_version() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: 99,
        SaveSchemaScript.KEY_WALLET_COINS: 4,
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_negative_wallet_balance() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
        SaveSchemaScript.KEY_WALLET_COINS: -1,
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_missing_required_fields() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_delete_snapshot_clears_saved_presence() -> void:
    var local_storage: RefCounted = InMemoryLocalStorageAdapterScript.new()
    var save_storage = SaveStorageScript.new(local_storage)

    var snapshot: RefCounted = SaveSnapshotScript.new(5)
    save_storage.save_snapshot(snapshot)
    save_storage.delete_snapshot()

    assert_false(save_storage.has_snapshot())