extends GutTest

const AppSettingsAndSaveStorageRuntimeScript = preload("res://src/platform/storage/app_settings_and_save_storage_runtime.gd")
const AppSettingsStorageScript = preload("res://src/platform/storage/app_settings_storage.gd")
const AudioSettingsAdapterScript = preload("res://src/platform/audio/audio_settings_adapter.gd")
const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const HapticFeedbackTypeScript = preload("res://src/platform/haptics/haptic_feedback_type.gd")
const HapticsAdapterScript = preload("res://src/platform/haptics/haptics_adapter.gd")
const InMemoryLocalStorageAdapterScript = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

class StubAudioSettingsAdapter extends AudioSettingsAdapterScript:
    var _master_volume_ratio: float = 1.0
    var _muted: bool = false

    func apply_master_settings(master_volume_ratio: float, muted: bool) -> void:
        _master_volume_ratio = master_volume_ratio
        _muted = muted

    var music_volume_ratio: float = 1.0

    func apply_music_settings(ratio: float) -> void:
        music_volume_ratio = ratio

    func get_master_volume_ratio() -> float:
        return _master_volume_ratio

    func is_master_muted() -> bool:
        return _muted

class StubHapticsAdapter extends HapticsAdapterScript:
    var _supported_feedback_types: PackedInt32Array = PackedInt32Array()
    var triggered_feedback_types: PackedInt32Array = PackedInt32Array()

    func _init(supported_feedback_types: PackedInt32Array = PackedInt32Array()) -> void:
        _supported_feedback_types = supported_feedback_types.duplicate()

    func supports_feedback(feedback_type: int) -> bool:
        return _supported_feedback_types.has(feedback_type)

    func trigger_feedback(feedback_type: int) -> void:
        var _append_result: bool = triggered_feedback_types.append(feedback_type)

func test_runtime_persists_app_settings_mutations_and_applies_audio_settings() -> void:
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var runtime: AppSettingsAndSaveStorageRuntime = AppSettingsAndSaveStorageRuntimeScript.new(local_storage)
    var audio_settings_adapter: StubAudioSettingsAdapter = StubAudioSettingsAdapter.new()
    var app_settings_storage: AppSettingsStorageScript = AppSettingsStorageScript.new(local_storage)

    runtime.load_or_create_app_settings()
    runtime.set_audio_muted(true, audio_settings_adapter)
    runtime.set_master_volume_ratio(0.25, audio_settings_adapter)
    runtime.set_touch_split_ratio(0.35)
    runtime.set_touch_center_dead_zone_ratio(0.1)

    assert_true(app_settings_storage.has_snapshot())
    assert_true(audio_settings_adapter.is_master_muted())
    assert_eq(audio_settings_adapter.get_master_volume_ratio(), 0.25)
    assert_true(app_settings_storage.load_snapshot().audio_muted)
    assert_eq(app_settings_storage.load_snapshot().master_volume_ratio, 0.25)
    assert_eq(app_settings_storage.load_snapshot().touch_split_ratio, 0.35)
    assert_eq(app_settings_storage.load_snapshot().touch_center_dead_zone_ratio, 0.1)

func test_runtime_hydrates_save_state_and_applies_saved_cosmetic_selection() -> void:
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var runtime: AppSettingsAndSaveStorageRuntime = AppSettingsAndSaveStorageRuntimeScript.new(local_storage)
    var cosmetic_item_catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript
    var cosmetic_loadout_resource: Resource = load("res://resources/config/cosmetic_loadout_default.tres")
    var cosmetic_loadout: CosmeticLoadoutScript = cosmetic_loadout_resource.duplicate(true) as CosmeticLoadoutScript
    var cosmetic_loadout_service: CosmeticLoadoutServiceScript = CosmeticLoadoutServiceScript.new()
    var save_snapshot: SaveSnapshotScript = SaveSnapshotScript.new(
        12,
        SaveSchemaScript.VERSION,
        &"hot_coffee",
        PackedStringArray(["ad_reward:continue_offer_01"]),
        PackedStringArray(["character_human", "body_default", "body_sunrise_jacket", "left_hand_default", "right_hand_default", "chaser_hot_coffee"]),
        &"body_sunrise_jacket",
        &"left_hand_default",
        &"right_hand_default",
        &"human"
    )

    runtime.set_save_snapshot(save_snapshot)
    var wallet: WalletScript = runtime.create_wallet_from_save_snapshot()
    var persistent_transaction_ledger: CoinTransactionLedgerScript = runtime.create_persistent_transaction_ledger_from_save_snapshot()
    var cosmetic_inventory: CosmeticInventoryScript = runtime.create_cosmetic_inventory_from_save_snapshot(cosmetic_item_catalog)

    assert_eq(wallet.get_coins(), 12)
    assert_true(persistent_transaction_ledger.has_transaction_id("ad_reward:continue_offer_01"))
    assert_true(cosmetic_inventory.is_owned(&"body_sunrise_jacket"))

    runtime.apply_saved_cosmetic_selection(
        cosmetic_loadout,
        cosmetic_inventory,
        cosmetic_item_catalog,
        cosmetic_loadout_service
    )

    assert_eq(cosmetic_loadout.player_appearance_id, &"human")
    assert_eq(cosmetic_loadout.chaser_theme_id, &"hot_coffee")
    assert_eq(cosmetic_loadout.body_cosmetic_id, &"body_sunrise_jacket")

func test_runtime_persists_save_state_from_runtime_models() -> void:
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var runtime: AppSettingsAndSaveStorageRuntime = AppSettingsAndSaveStorageRuntimeScript.new(local_storage)
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
    var cosmetic_item_catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript
    var cosmetic_loadout_resource: Resource = load("res://resources/config/cosmetic_loadout_default.tres")
    var cosmetic_loadout: CosmeticLoadoutScript = cosmetic_loadout_resource.duplicate(true) as CosmeticLoadoutScript
    var wallet: WalletScript = WalletScript.new(28)
    var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new(
        PackedStringArray(["purchase:cosmetic_unlock:body_sunrise_jacket"])
    )
    var cosmetic_inventory: CosmeticInventoryScript = CosmeticInventoryScript.new(
        PackedStringArray(["body_sunrise_jacket"]),
        cosmetic_item_catalog.get_default_unlocked_item_ids()
    )

    cosmetic_loadout.body_cosmetic_id = &"body_sunrise_jacket"
    runtime.persist_save_state(
        wallet,
        persistent_transaction_ledger,
        cosmetic_inventory,
        cosmetic_loadout,
        cosmetic_item_catalog
    )

    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, 28)
    assert_eq(save_storage.load_snapshot().player_appearance_id, &"human")
    assert_eq(save_storage.load_snapshot().body_cosmetic_id, &"body_sunrise_jacket")
    assert_true(save_storage.load_snapshot().owned_cosmetic_ids.has("body_sunrise_jacket"))
    assert_eq(
        save_storage.load_snapshot().applied_persistent_transaction_ids,
        PackedStringArray(["purchase:cosmetic_unlock:body_sunrise_jacket"])
    )

func test_runtime_triggers_haptics_only_when_enabled_and_supported() -> void:
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var runtime: AppSettingsAndSaveStorageRuntime = AppSettingsAndSaveStorageRuntimeScript.new(local_storage)
    var haptics_adapter: StubHapticsAdapter = StubHapticsAdapter.new(PackedInt32Array([HapticFeedbackTypeScript.Value.WARNING]))

    runtime.load_or_create_app_settings()
    runtime.trigger_haptic_feedback(HapticFeedbackTypeScript.Value.WARNING, haptics_adapter)
    runtime.set_haptics_enabled(false)
    runtime.trigger_haptic_feedback(HapticFeedbackTypeScript.Value.WARNING, haptics_adapter)

    assert_eq(haptics_adapter.triggered_feedback_types, PackedInt32Array([HapticFeedbackTypeScript.Value.WARNING]))