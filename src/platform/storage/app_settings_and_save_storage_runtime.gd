# Strictly typed runtime for app settings and save storage orchestration
# Godot 4.4+ GDScript, strict typing, fail-fast, no fallback
class_name AppSettingsAndSaveStorageRuntime
extends RefCounted

const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const AppSettingsStorageScript = preload("res://src/platform/storage/app_settings_storage.gd")
const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemScript = preload("res://resources/config/cosmetic_item.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")
const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")
const JsonFileLocalStorageAdapterScript = preload("res://src/platform/storage/json_file_local_storage_adapter.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

# State
var app_settings_storage: AppSettingsStorageScript
var app_settings_snapshot: AppSettingsSnapshotScript
var save_storage: SaveStorageScript
var save_snapshot: SaveSnapshotScript
var local_storage_adapter: LocalStorageAdapterScript

func _init(initial_local_storage_adapter: LocalStorageAdapterScript = null) -> void:
	var resolved_local_storage_adapter: LocalStorageAdapterScript = initial_local_storage_adapter
	if resolved_local_storage_adapter == null:
		resolved_local_storage_adapter = JsonFileLocalStorageAdapterScript.new()
	self.local_storage_adapter = resolved_local_storage_adapter
	app_settings_storage = AppSettingsStorageScript.new(resolved_local_storage_adapter)
	save_storage = SaveStorageScript.new(resolved_local_storage_adapter)
	app_settings_snapshot = null
	save_snapshot = null

func initialize_app_settings_storage() -> void:
	app_settings_storage = AppSettingsStorageScript.new(local_storage_adapter)

func initialize_save_storage() -> void:
	save_storage = SaveStorageScript.new(local_storage_adapter)

func load_or_create_app_settings() -> void:
	Validation.require_condition(app_settings_storage != null, "AppSettingsAndSaveStorageRuntime requires app settings storage before loading.")
	if app_settings_storage.has_snapshot():
		app_settings_snapshot = app_settings_storage.load_snapshot()
	else:
		app_settings_snapshot = AppSettingsSnapshotScript.new()

func persist_app_settings() -> void:
	Validation.require_condition(app_settings_storage != null, "AppSettingsAndSaveStorageRuntime requires app settings storage before saving.")
	Validation.require_condition(app_settings_snapshot != null, "AppSettingsAndSaveStorageRuntime requires app settings before saving.")
	app_settings_snapshot.assert_valid()
	app_settings_storage.save_snapshot(app_settings_snapshot)

func load_or_create_save_state(default_loadout: CosmeticLoadoutScript, cosmetic_item_catalog: CosmeticItemCatalogScript) -> void:
	Validation.require_condition(save_storage != null, "AppSettingsAndSaveStorageRuntime requires save storage before loading.")
	Validation.require_condition(default_loadout != null, "AppSettingsAndSaveStorageRuntime requires a default cosmetic loadout before loading save state.")
	Validation.require_condition(cosmetic_item_catalog != null, "AppSettingsAndSaveStorageRuntime requires a cosmetic item catalog before loading save state.")
	if save_snapshot == null:
		if save_storage.has_snapshot():
			save_snapshot = save_storage.load_snapshot()
		else:
			save_snapshot = SaveSnapshotScript.new(
				0,
				SaveSchemaScript.VERSION,
				default_loadout.chaser_theme_id,
				PackedStringArray(),
				_get_owned_item_ids_for_new_save(default_loadout, cosmetic_item_catalog),
				default_loadout.body_cosmetic_id,
				default_loadout.left_hand_cosmetic_id,
				default_loadout.right_hand_cosmetic_id
			)
func persist_save_state(
	wallet: WalletScript,
	persistent_transaction_ledger: CoinTransactionLedgerScript,
	cosmetic_inventory: CosmeticInventoryScript,
	cosmetic_loadout: CosmeticLoadoutScript,
	cosmetic_item_catalog: CosmeticItemCatalogScript
) -> void:
	Validation.require_condition(save_storage != null, "AppSettingsAndSaveStorageRuntime requires save storage before persisting save state.")
	Validation.require_condition(wallet != null, "AppSettingsAndSaveStorageRuntime requires a wallet before persisting save state.")
	Validation.require_condition(persistent_transaction_ledger != null, "AppSettingsAndSaveStorageRuntime requires a transaction ledger before persisting save state.")
	Validation.require_condition(cosmetic_inventory != null, "AppSettingsAndSaveStorageRuntime requires cosmetic inventory before persisting save state.")
	Validation.require_condition(cosmetic_loadout != null, "AppSettingsAndSaveStorageRuntime requires a cosmetic loadout before persisting save state.")
	Validation.require_condition(cosmetic_item_catalog != null, "AppSettingsAndSaveStorageRuntime requires a cosmetic item catalog before persisting save state.")
	cosmetic_loadout.assert_valid()
	var snapshot: SaveSnapshotScript = SaveSnapshotScript.new(
		wallet.get_coins(),
		SaveSchemaScript.VERSION,
		cosmetic_loadout.chaser_theme_id,
		persistent_transaction_ledger.get_transaction_ids(),
		cosmetic_inventory.get_owned_item_ids(),
		cosmetic_loadout.body_cosmetic_id,
		cosmetic_loadout.left_hand_cosmetic_id,
		cosmetic_loadout.right_hand_cosmetic_id
	)
	save_storage.save_snapshot(snapshot)
	save_snapshot = snapshot

func set_local_storage_adapter(adapter: LocalStorageAdapterScript) -> void:
	Validation.require_condition(adapter != null, "AppSettingsAndSaveStorageRuntime requires a local storage adapter.")
	Validation.require_condition(adapter is LocalStorageAdapterScript, "AppSettingsAndSaveStorageRuntime requires a LocalStorageAdapter implementation.")
	local_storage_adapter = adapter
	initialize_save_storage()
	initialize_app_settings_storage()

func set_save_snapshot(snapshot: SaveSnapshotScript) -> void:
	Validation.require_condition(snapshot != null, "AppSettingsAndSaveStorageRuntime requires a save snapshot.")
	snapshot.assert_valid()
	save_snapshot = snapshot

func has_save_snapshot() -> bool:
	return save_snapshot != null

func get_save_snapshot() -> SaveSnapshotScript:
	Validation.require_condition(save_snapshot != null, "AppSettingsAndSaveStorageRuntime requires a save snapshot before access.")
	return save_snapshot

func get_app_settings_snapshot() -> AppSettingsSnapshotScript:
	Validation.require_condition(app_settings_snapshot != null, "AppSettingsAndSaveStorageRuntime requires app settings before access.")
	return app_settings_snapshot

func _get_owned_item_ids_for_new_save(loadout: CosmeticLoadoutScript, cosmetic_item_catalog: CosmeticItemCatalogScript) -> PackedStringArray:
	Validation.require_condition(loadout != null, "AppSettingsAndSaveStorageRuntime requires a cosmetic loadout when creating owned item ids.")
	Validation.require_condition(cosmetic_item_catalog != null, "AppSettingsAndSaveStorageRuntime requires a cosmetic item catalog when creating owned item ids.")
	var owned_item_ids: PackedStringArray = cosmetic_item_catalog.get_default_unlocked_item_ids()
	_append_unique_owned_item_id(owned_item_ids, loadout.body_cosmetic_id)
	_append_unique_owned_item_id(owned_item_ids, loadout.left_hand_cosmetic_id)
	_append_unique_owned_item_id(owned_item_ids, loadout.right_hand_cosmetic_id)
	var chaser_item: CosmeticItemScript = cosmetic_item_catalog.get_required_chaser_item_by_theme_id(loadout.chaser_theme_id)
	_append_unique_owned_item_id(owned_item_ids, chaser_item.item_id)
	return owned_item_ids

func _append_unique_owned_item_id(owned_item_ids: PackedStringArray, item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "AppSettingsAndSaveStorageRuntime new save owned item id cannot be empty.")
	var item_id_string: String = String(item_id)
	if not owned_item_ids.has(item_id_string):
		var _append_result: bool = owned_item_ids.append(item_id_string)
