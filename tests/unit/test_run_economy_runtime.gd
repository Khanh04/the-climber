extends GutTest

const AppSettingsAndSaveStorageRuntimeScript = preload("res://src/platform/storage/app_settings_and_save_storage_runtime.gd")
const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const CosmeticUnlockPurchaseServiceScript = preload("res://src/cosmetics/cosmetic_unlock_purchase_service.gd")
const InMemoryLocalStorageAdapterScript = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const PostRunCoinDoublerGrantServiceScript = preload("res://src/economy/post_run_coin_doubler_grant_service.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const RunEconomyRuntimeScript = preload("res://src/gameplay/run/run_economy_runtime.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func test_apply_persistent_coin_transaction_applies_once() -> void:
	var runtime: RunEconomyRuntime = RunEconomyRuntimeScript.new()
	var wallet: WalletScript = WalletScript.new(0)
	var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()

	assert_true(runtime.apply_persistent_coin_transaction(
		wallet,
		persistent_transaction_ledger,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		"ad_reward:continue_offer_01",
		TransactionSourceScript.Value.AD_REWARD,
		9
	))
	assert_eq(wallet.get_coins(), 9)
	assert_true(persistent_transaction_ledger.has_transaction_id("ad_reward:continue_offer_01"))
	assert_false(runtime.apply_persistent_coin_transaction(
		wallet,
		persistent_transaction_ledger,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		"ad_reward:continue_offer_01",
		TransactionSourceScript.Value.AD_REWARD,
		9
	))
	assert_eq(wallet.get_coins(), 9)

func test_apply_persistent_coin_transaction_and_persist_updates_save_snapshot() -> void:
	var runtime: RunEconomyRuntime = RunEconomyRuntimeScript.new()
	var catalog: CosmeticItemCatalogScript = _load_catalog()
	var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
	var storage_runtime: AppSettingsAndSaveStorageRuntime = AppSettingsAndSaveStorageRuntimeScript.new(local_storage)
	var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
	var wallet: WalletScript = WalletScript.new(0)
	var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var cosmetic_inventory: CosmeticInventoryScript = CosmeticInventoryScript.new(PackedStringArray(), catalog.get_default_unlocked_item_ids())
	var cosmetic_loadout: CosmeticLoadoutScript = CosmeticLoadoutScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()

	assert_true(runtime.apply_persistent_coin_transaction_and_persist(
		storage_runtime,
		wallet,
		persistent_transaction_ledger,
		cosmetic_inventory,
		cosmetic_loadout,
		catalog,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		"ad_reward:continue_offer_01",
		TransactionSourceScript.Value.AD_REWARD,
		9
	))
	assert_true(save_storage.has_snapshot())
	assert_eq(save_storage.load_snapshot().wallet_coins, 9)
	assert_eq(save_storage.load_snapshot().applied_persistent_transaction_ids, PackedStringArray(["ad_reward:continue_offer_01"]))

func test_purchase_and_equip_cosmetic_item_updates_inventory_wallet_and_loadout() -> void:
	var runtime: RunEconomyRuntime = RunEconomyRuntimeScript.new()
	var catalog: CosmeticItemCatalogScript = _load_catalog()
	var wallet: WalletScript = WalletScript.new(40)
	var cosmetic_inventory: CosmeticInventoryScript = CosmeticInventoryScript.new(PackedStringArray(), catalog.get_default_unlocked_item_ids())
	var cosmetic_loadout: CosmeticLoadoutScript = CosmeticLoadoutScript.new()
	var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
	var cosmetic_unlock_purchase_service: CosmeticUnlockPurchaseServiceScript = CosmeticUnlockPurchaseServiceScript.new()
	var cosmetic_loadout_service: CosmeticLoadoutServiceScript = CosmeticLoadoutServiceScript.new()

	var purchase_result: CosmeticPurchaseResultScript = runtime.purchase_cosmetic_item(
		wallet,
		cosmetic_inventory,
		catalog,
		persistent_transaction_ledger,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		cosmetic_unlock_purchase_service,
		&"body_sunrise_jacket"
	)

	assert_eq(purchase_result.outcome, CosmeticPurchaseOutcomeScript.Value.PURCHASED)
	assert_eq(wallet.get_coins(), 28)
	assert_true(cosmetic_inventory.is_owned(&"body_sunrise_jacket"))
	assert_true(persistent_transaction_ledger.has_transaction_id("purchase:cosmetic_unlock:body_sunrise_jacket"))

	runtime.equip_cosmetic_item(
		cosmetic_loadout,
		cosmetic_inventory,
		catalog,
		cosmetic_loadout_service,
		&"body_sunrise_jacket"
	)

	assert_eq(cosmetic_loadout.body_cosmetic_id, &"body_sunrise_jacket")

func test_purchase_and_equip_cosmetic_item_and_persist_updates_save_snapshot() -> void:
	var runtime: RunEconomyRuntime = RunEconomyRuntimeScript.new()
	var catalog: CosmeticItemCatalogScript = _load_catalog()
	var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
	var storage_runtime: AppSettingsAndSaveStorageRuntime = AppSettingsAndSaveStorageRuntimeScript.new(local_storage)
	var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
	var wallet: WalletScript = WalletScript.new(40)
	var cosmetic_inventory: CosmeticInventoryScript = CosmeticInventoryScript.new(PackedStringArray(), catalog.get_default_unlocked_item_ids())
	var cosmetic_loadout: CosmeticLoadoutScript = CosmeticLoadoutScript.new()
	var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
	var cosmetic_unlock_purchase_service: CosmeticUnlockPurchaseServiceScript = CosmeticUnlockPurchaseServiceScript.new()
	var cosmetic_loadout_service: CosmeticLoadoutServiceScript = CosmeticLoadoutServiceScript.new()

	var purchase_result: CosmeticPurchaseResultScript = runtime.purchase_cosmetic_item_and_persist(
		storage_runtime,
		wallet,
		cosmetic_inventory,
		catalog,
		persistent_transaction_ledger,
		cosmetic_loadout,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		cosmetic_unlock_purchase_service,
		&"body_sunrise_jacket"
	)
	assert_eq(purchase_result.outcome, CosmeticPurchaseOutcomeScript.Value.PURCHASED)
	assert_eq(save_storage.load_snapshot().wallet_coins, 28)
	assert_true(save_storage.load_snapshot().owned_cosmetic_ids.has("body_sunrise_jacket"))

	runtime.equip_cosmetic_item_and_persist(
		storage_runtime,
		wallet,
		persistent_transaction_ledger,
		cosmetic_inventory,
		cosmetic_loadout,
		catalog,
		cosmetic_loadout_service,
		&"body_sunrise_jacket"
	)
	assert_eq(save_storage.load_snapshot().body_cosmetic_id, &"body_sunrise_jacket")

func test_apply_post_run_coin_doubler_reward_and_persist_updates_save_snapshot() -> void:
	var runtime: RunEconomyRuntime = RunEconomyRuntimeScript.new()
	var catalog: CosmeticItemCatalogScript = _load_catalog()
	var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
	var storage_runtime: AppSettingsAndSaveStorageRuntime = AppSettingsAndSaveStorageRuntimeScript.new(local_storage)
	var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
	var wallet: WalletScript = WalletScript.new(5)
	var persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
	var cosmetic_inventory: CosmeticInventoryScript = CosmeticInventoryScript.new(PackedStringArray(), catalog.get_default_unlocked_item_ids())
	var cosmetic_loadout: CosmeticLoadoutScript = CosmeticLoadoutScript.new()
	var wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
	var persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
	var post_run_coin_doubler_grant_service: PostRunCoinDoublerGrantServiceScript = PostRunCoinDoublerGrantServiceScript.new()
	var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
		RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER,
		RewardedAdOutcomeScript.Value.COMPLETED,
		true
	)

	assert_true(runtime.apply_post_run_coin_doubler_reward_and_persist(
		storage_runtime,
		wallet,
		persistent_transaction_ledger,
		cosmetic_inventory,
		cosmetic_loadout,
		catalog,
		wallet_transaction_service,
		persistent_coin_transaction_service,
		post_run_coin_doubler_grant_service,
		rewarded_ad_result,
		"summary_01",
		7
	))
	assert_eq(save_storage.load_snapshot().wallet_coins, 12)
	assert_eq(
		save_storage.load_snapshot().applied_persistent_transaction_ids,
		PackedStringArray(["ad_reward:post_run_coin_doubler:summary_01"])
	)

func _load_catalog() -> CosmeticItemCatalogScript:
	var catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript
	assert_not_null(catalog)
	return catalog