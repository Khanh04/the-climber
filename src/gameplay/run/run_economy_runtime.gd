class_name RunEconomyRuntime
extends RefCounted

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const CosmeticUnlockPurchaseServiceScript = preload("res://src/cosmetics/cosmetic_unlock_purchase_service.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func apply_persistent_coin_transaction(
	wallet: RefCounted,
	persistent_transaction_ledger: RefCounted,
	wallet_transaction_service: RefCounted,
	persistent_coin_transaction_service: RefCounted,
	transaction_id: String,
	source: int,
	coin_delta: int
) -> bool:
	var typed_persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = _require_persistent_coin_transaction_service(persistent_coin_transaction_service)
	return typed_persistent_coin_transaction_service.apply_persistent_transaction(
		_require_wallet(wallet),
		_require_transaction_ledger(persistent_transaction_ledger),
		_require_wallet_transaction_service(wallet_transaction_service),
		transaction_id,
		source,
		coin_delta
	)

func purchase_cosmetic_item(
	wallet: RefCounted,
	cosmetic_inventory: RefCounted,
	cosmetic_item_catalog: Resource,
	persistent_transaction_ledger: RefCounted,
	wallet_transaction_service: RefCounted,
	persistent_coin_transaction_service: RefCounted,
	cosmetic_unlock_purchase_service: RefCounted,
	item_id: StringName
) -> CosmeticPurchaseResultScript:
	Validation.require_condition(not item_id.is_empty(), "RunEconomyRuntime cosmetic purchase item id cannot be empty.")
	var typed_cosmetic_unlock_purchase_service: CosmeticUnlockPurchaseServiceScript = _require_cosmetic_unlock_purchase_service(cosmetic_unlock_purchase_service)
	return typed_cosmetic_unlock_purchase_service.purchase_item(
		_require_wallet(wallet),
		_require_cosmetic_inventory(cosmetic_inventory),
		_require_cosmetic_item_catalog(cosmetic_item_catalog),
		_require_transaction_ledger(persistent_transaction_ledger),
		_require_wallet_transaction_service(wallet_transaction_service),
		_require_persistent_coin_transaction_service(persistent_coin_transaction_service),
		item_id
	)

func equip_cosmetic_item(
	cosmetic_loadout: Resource,
	cosmetic_inventory: RefCounted,
	cosmetic_item_catalog: Resource,
	cosmetic_loadout_service: RefCounted,
	item_id: StringName
) -> void:
	Validation.require_condition(not item_id.is_empty(), "RunEconomyRuntime cosmetic equip item id cannot be empty.")
	var typed_cosmetic_loadout_service: CosmeticLoadoutServiceScript = _require_cosmetic_loadout_service(cosmetic_loadout_service)
	typed_cosmetic_loadout_service.equip_item(
		_require_cosmetic_loadout(cosmetic_loadout),
		_require_cosmetic_inventory(cosmetic_inventory),
		_require_cosmetic_item_catalog(cosmetic_item_catalog),
		item_id
	)

func _require_wallet(wallet: RefCounted) -> WalletScript:
	Validation.require_condition(wallet != null, "RunEconomyRuntime requires a wallet.")
	Validation.require_condition(wallet is WalletScript, "RunEconomyRuntime requires Wallet.")
	return wallet as WalletScript

func _require_transaction_ledger(persistent_transaction_ledger: RefCounted) -> CoinTransactionLedgerScript:
	Validation.require_condition(persistent_transaction_ledger != null, "RunEconomyRuntime requires a transaction ledger.")
	Validation.require_condition(persistent_transaction_ledger is CoinTransactionLedgerScript, "RunEconomyRuntime requires CoinTransactionLedger.")
	return persistent_transaction_ledger as CoinTransactionLedgerScript

func _require_wallet_transaction_service(wallet_transaction_service: RefCounted) -> WalletTransactionServiceScript:
	Validation.require_condition(wallet_transaction_service != null, "RunEconomyRuntime requires a wallet transaction service.")
	Validation.require_condition(wallet_transaction_service is WalletTransactionServiceScript, "RunEconomyRuntime requires WalletTransactionService.")
	return wallet_transaction_service as WalletTransactionServiceScript

func _require_persistent_coin_transaction_service(persistent_coin_transaction_service: RefCounted) -> PersistentCoinTransactionServiceScript:
	Validation.require_condition(persistent_coin_transaction_service != null, "RunEconomyRuntime requires a persistent coin transaction service.")
	Validation.require_condition(
		persistent_coin_transaction_service is PersistentCoinTransactionServiceScript,
		"RunEconomyRuntime requires PersistentCoinTransactionService."
	)
	return persistent_coin_transaction_service as PersistentCoinTransactionServiceScript

func _require_cosmetic_inventory(cosmetic_inventory: RefCounted) -> CosmeticInventoryScript:
	Validation.require_condition(cosmetic_inventory != null, "RunEconomyRuntime requires a cosmetic inventory.")
	Validation.require_condition(cosmetic_inventory is CosmeticInventoryScript, "RunEconomyRuntime requires CosmeticInventory.")
	return cosmetic_inventory as CosmeticInventoryScript

func _require_cosmetic_item_catalog(cosmetic_item_catalog: Resource) -> CosmeticItemCatalogScript:
	Validation.require_condition(cosmetic_item_catalog != null, "RunEconomyRuntime requires a cosmetic item catalog.")
	Validation.require_condition(cosmetic_item_catalog is CosmeticItemCatalogScript, "RunEconomyRuntime requires CosmeticItemCatalog.")
	var typed_cosmetic_item_catalog: CosmeticItemCatalogScript = cosmetic_item_catalog as CosmeticItemCatalogScript
	typed_cosmetic_item_catalog.assert_valid()
	return typed_cosmetic_item_catalog

func _require_cosmetic_loadout(cosmetic_loadout: Resource) -> CosmeticLoadoutScript:
	Validation.require_condition(cosmetic_loadout != null, "RunEconomyRuntime requires a cosmetic loadout.")
	Validation.require_condition(cosmetic_loadout is CosmeticLoadoutScript, "RunEconomyRuntime requires CosmeticLoadout.")
	return cosmetic_loadout as CosmeticLoadoutScript

func _require_cosmetic_unlock_purchase_service(cosmetic_unlock_purchase_service: RefCounted) -> CosmeticUnlockPurchaseServiceScript:
	Validation.require_condition(cosmetic_unlock_purchase_service != null, "RunEconomyRuntime requires a cosmetic unlock purchase service.")
	Validation.require_condition(
		cosmetic_unlock_purchase_service is CosmeticUnlockPurchaseServiceScript,
		"RunEconomyRuntime requires CosmeticUnlockPurchaseService."
	)
	return cosmetic_unlock_purchase_service as CosmeticUnlockPurchaseServiceScript

func _require_cosmetic_loadout_service(cosmetic_loadout_service: RefCounted) -> CosmeticLoadoutServiceScript:
	Validation.require_condition(cosmetic_loadout_service != null, "RunEconomyRuntime requires a cosmetic loadout service.")
	Validation.require_condition(cosmetic_loadout_service is CosmeticLoadoutServiceScript, "RunEconomyRuntime requires CosmeticLoadoutService.")
	return cosmetic_loadout_service as CosmeticLoadoutServiceScript