extends GutTest

const InMemoryLocalStorageAdapterScript = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")

func test_save_snapshot_round_trips_through_local_storage() -> void:
    var local_storage: RefCounted = InMemoryLocalStorageAdapterScript.new()
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
    var owned_cosmetic_ids := PackedStringArray(["body_default", "left_hand_default", "right_hand_default", "chaser_glitch"])
    var snapshot: RefCounted = SaveSnapshotScript.new(
        42,
        SaveSchemaScript.VERSION,
        &"glitch",
        PackedStringArray(["ad_reward:daily_2026-05-14"]),
        owned_cosmetic_ids,
        &"body_default",
        &"left_hand_default",
        &"right_hand_default"
    )

    save_storage.save_snapshot(snapshot)

    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, 42)
    assert_eq(save_storage.load_snapshot().chaser_theme_id, &"glitch")
    assert_eq(save_storage.load_snapshot().body_cosmetic_id, &"body_default")
    assert_eq(save_storage.load_snapshot().left_hand_cosmetic_id, &"left_hand_default")
    assert_eq(save_storage.load_snapshot().right_hand_cosmetic_id, &"right_hand_default")
    assert_eq(save_storage.load_snapshot().owned_cosmetic_ids, owned_cosmetic_ids)
    assert_eq(save_storage.load_snapshot().applied_persistent_transaction_ids, PackedStringArray(["ad_reward:daily_2026-05-14"]))

func test_save_snapshot_dictionary_validation_rejects_unsupported_schema_version() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: 99,
        SaveSchemaScript.KEY_WALLET_COINS: 4,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "rising_void",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "body_default",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: [],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: [],
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_from_dictionary_accepts_integer_valued_json_numbers() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: float(SaveSchemaScript.VERSION),
        SaveSchemaScript.KEY_WALLET_COINS: 4.0,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "glitch",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "body_default",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: ["body_default", "left_hand_default", "right_hand_default", "chaser_glitch"],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: ["ad_reward:post_run_coin_doubler:run_summary_7"],
    }

    assert_true(SaveSnapshotScript.is_dictionary_valid(payload))

    var raw_snapshot: RefCounted = SaveSnapshotScript.from_dictionary(payload)

    assert_true(raw_snapshot is SaveSnapshotScript)
    var snapshot: SaveSnapshotScript = raw_snapshot as SaveSnapshotScript
    assert_eq(snapshot.schema_version, SaveSchemaScript.VERSION)
    assert_eq(snapshot.wallet_coins, 4)
    assert_eq(snapshot.chaser_theme_id, &"glitch")
    assert_eq(snapshot.body_cosmetic_id, &"body_default")
    assert_eq(snapshot.left_hand_cosmetic_id, &"left_hand_default")
    assert_eq(snapshot.right_hand_cosmetic_id, &"right_hand_default")
    assert_eq(snapshot.owned_cosmetic_ids, PackedStringArray(["body_default", "left_hand_default", "right_hand_default", "chaser_glitch"]))
    assert_eq(snapshot.applied_persistent_transaction_ids, PackedStringArray(["ad_reward:post_run_coin_doubler:run_summary_7"]))

func test_save_snapshot_dictionary_validation_rejects_negative_wallet_balance() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
        SaveSchemaScript.KEY_WALLET_COINS: -1,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "rising_void",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "body_default",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: [],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: [],
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_missing_required_fields() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_empty_chaser_theme_id() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
        SaveSchemaScript.KEY_WALLET_COINS: 4,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "body_default",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: [],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: [],
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_duplicate_transaction_ids() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
        SaveSchemaScript.KEY_WALLET_COINS: 4,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "rising_void",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "body_default",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: [],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: ["purchase:starter_pack", "purchase:starter_pack"],
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_empty_transaction_ids() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
        SaveSchemaScript.KEY_WALLET_COINS: 4,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "rising_void",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "body_default",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: [],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: [""],
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_duplicate_owned_cosmetic_ids() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
        SaveSchemaScript.KEY_WALLET_COINS: 4,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "rising_void",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "body_default",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: ["body_default", "body_default"],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: [],
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_save_snapshot_dictionary_validation_rejects_empty_body_cosmetic_id() -> void:
    var payload: Dictionary = {
        SaveSchemaScript.KEY_SCHEMA_VERSION: SaveSchemaScript.VERSION,
        SaveSchemaScript.KEY_WALLET_COINS: 4,
        SaveSchemaScript.KEY_CHASER_THEME_ID: "rising_void",
        SaveSchemaScript.KEY_BODY_COSMETIC_ID: "",
        SaveSchemaScript.KEY_LEFT_HAND_COSMETIC_ID: "left_hand_default",
        SaveSchemaScript.KEY_RIGHT_HAND_COSMETIC_ID: "right_hand_default",
        SaveSchemaScript.KEY_OWNED_COSMETIC_IDS: [],
        SaveSchemaScript.KEY_APPLIED_PERSISTENT_TRANSACTION_IDS: [],
    }

    assert_false(SaveSnapshotScript.is_dictionary_valid(payload))

func test_delete_snapshot_clears_saved_presence() -> void:
    var local_storage: RefCounted = InMemoryLocalStorageAdapterScript.new()
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)

    var snapshot: RefCounted = SaveSnapshotScript.new(5, SaveSchemaScript.VERSION, &"hot_coffee")
    save_storage.save_snapshot(snapshot)
    save_storage.delete_snapshot()

    assert_false(save_storage.has_snapshot())