extends GutTest

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const CosmeticUnlockPurchaseServiceScript = preload("res://src/cosmetics/cosmetic_unlock_purchase_service.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const RunEconomyRuntimeScript = preload("res://src/gameplay/run/run_economy_runtime.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func test_apply_persistent_coin_transaction_applies_once() -> void:
	var runtime: RunEconomyRuntimeScript = RunEconomyRuntimeScript.new()
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

func test_purchase_and_equip_cosmetic_item_updates_inventory_wallet_and_loadout() -> void:
	var runtime: RunEconomyRuntimeScript = RunEconomyRuntimeScript.new()
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

func _load_catalog() -> CosmeticItemCatalogScript:
	var catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript
	assert_not_null(catalog)
	return catalog