class_name CosmeticUnlockPurchaseService
extends RefCounted

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticItemScript = preload("res://resources/config/cosmetic_item.gd")
const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func purchase_item(
	wallet: RefCounted,
	inventory: RefCounted,
	catalog: Resource,
	persistent_transaction_ledger: RefCounted,
	wallet_transaction_service: RefCounted,
	persistent_coin_transaction_service: RefCounted,
	item_id: StringName
) -> CosmeticPurchaseResultScript:
	var typed_wallet: WalletScript = _require_wallet(wallet)
	var typed_inventory: CosmeticInventoryScript = _require_inventory(inventory)
	var typed_catalog: CosmeticItemCatalogScript = _require_catalog(catalog)
	var typed_ledger: CoinTransactionLedgerScript = _require_ledger(persistent_transaction_ledger)
	var typed_wallet_transaction_service: WalletTransactionServiceScript = _require_wallet_transaction_service(wallet_transaction_service)
	var typed_persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = _require_persistent_coin_transaction_service(persistent_coin_transaction_service)
	var item: CosmeticItemScript = typed_catalog.get_required_item_by_id(item_id)

	if typed_inventory.is_owned(item.item_id):
		return CosmeticPurchaseResultScript.new(item.item_id, CosmeticPurchaseOutcomeScript.Value.ALREADY_OWNED, typed_wallet.get_coins())

	Validation.require_condition(item.price_coins > 0, "CosmeticUnlockPurchaseService purchasable items require a positive coin price.")
	if typed_wallet.get_coins() < item.price_coins:
		return CosmeticPurchaseResultScript.new(item.item_id, CosmeticPurchaseOutcomeScript.Value.INSUFFICIENT_FUNDS, typed_wallet.get_coins())

	var transaction_id: String = build_transaction_id(item.item_id)
	var transaction_applied: bool = typed_persistent_coin_transaction_service.apply_persistent_transaction(
		typed_wallet,
		typed_ledger,
		typed_wallet_transaction_service,
		transaction_id,
		TransactionSourceScript.Value.PURCHASE,
		-item.price_coins
	)
	Validation.require_condition(transaction_applied, "CosmeticUnlockPurchaseService purchase transaction must be new when the item is not owned.")
	var unlocked_now: bool = typed_inventory.unlock(item.item_id)
	Validation.require_condition(unlocked_now, "CosmeticUnlockPurchaseService must unlock the item after purchase.")
	return CosmeticPurchaseResultScript.new(item.item_id, CosmeticPurchaseOutcomeScript.Value.PURCHASED, typed_wallet.get_coins())

func build_transaction_id(item_id: StringName) -> String:
	Validation.require_condition(not item_id.is_empty(), "CosmeticUnlockPurchaseService transaction item id cannot be empty.")
	return "%s:cosmetic_unlock:%s" % [TransactionSourceScript.to_label(TransactionSourceScript.Value.PURCHASE), String(item_id)]

func _require_wallet(wallet: RefCounted) -> WalletScript:
	Validation.require_condition(wallet != null, "CosmeticUnlockPurchaseService requires a wallet.")
	Validation.require_condition(wallet is WalletScript, "CosmeticUnlockPurchaseService requires a Wallet implementation.")
	return wallet as WalletScript

func _require_inventory(inventory: RefCounted) -> CosmeticInventoryScript:
	Validation.require_condition(inventory != null, "CosmeticUnlockPurchaseService requires a cosmetic inventory.")
	Validation.require_condition(inventory is CosmeticInventoryScript, "CosmeticUnlockPurchaseService requires a CosmeticInventory implementation.")
	return inventory as CosmeticInventoryScript

func _require_catalog(catalog: Resource) -> CosmeticItemCatalogScript:
	Validation.require_condition(catalog != null, "CosmeticUnlockPurchaseService requires a cosmetic item catalog.")
	Validation.require_condition(catalog is CosmeticItemCatalogScript, "CosmeticUnlockPurchaseService requires a CosmeticItemCatalog resource.")
	var typed_catalog: CosmeticItemCatalogScript = catalog as CosmeticItemCatalogScript
	typed_catalog.assert_valid()
	return typed_catalog

func _require_ledger(ledger: RefCounted) -> CoinTransactionLedgerScript:
	Validation.require_condition(ledger != null, "CosmeticUnlockPurchaseService requires a persistent transaction ledger.")
	Validation.require_condition(ledger is CoinTransactionLedgerScript, "CosmeticUnlockPurchaseService requires a CoinTransactionLedger implementation.")
	return ledger as CoinTransactionLedgerScript

func _require_wallet_transaction_service(wallet_transaction_service: RefCounted) -> WalletTransactionServiceScript:
	Validation.require_condition(wallet_transaction_service != null, "CosmeticUnlockPurchaseService requires a wallet transaction service.")
	Validation.require_condition(wallet_transaction_service is WalletTransactionServiceScript, "CosmeticUnlockPurchaseService requires a WalletTransactionService implementation.")
	return wallet_transaction_service as WalletTransactionServiceScript

func _require_persistent_coin_transaction_service(persistent_coin_transaction_service: RefCounted) -> PersistentCoinTransactionServiceScript:
	Validation.require_condition(persistent_coin_transaction_service != null, "CosmeticUnlockPurchaseService requires a persistent coin transaction service.")
	Validation.require_condition(persistent_coin_transaction_service is PersistentCoinTransactionServiceScript, "CosmeticUnlockPurchaseService requires a PersistentCoinTransactionService implementation.")
	return persistent_coin_transaction_service as PersistentCoinTransactionServiceScript