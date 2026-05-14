class_name PersistentCoinTransactionService
extends RefCounted

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CoinTransactionScript = preload("res://src/economy/coin_transaction.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func apply_persistent_transaction(
	wallet: RefCounted,
	persistent_transaction_ledger: RefCounted,
	wallet_transaction_service: RefCounted,
	transaction_id: String,
	source: int,
	coin_delta: int
) -> bool:
	Validation.require_condition(wallet != null, "PersistentCoinTransactionService requires a wallet.")
	Validation.require_condition(wallet is WalletScript, "PersistentCoinTransactionService requires a Wallet implementation.")
	Validation.require_condition(persistent_transaction_ledger != null, "PersistentCoinTransactionService requires a persistent transaction ledger.")
	Validation.require_condition(persistent_transaction_ledger is CoinTransactionLedgerScript, "PersistentCoinTransactionService requires a CoinTransactionLedger implementation.")
	Validation.require_condition(wallet_transaction_service != null, "PersistentCoinTransactionService requires a wallet transaction service.")
	Validation.require_condition(wallet_transaction_service is WalletTransactionServiceScript, "PersistentCoinTransactionService requires a WalletTransactionService implementation.")
	Validation.require_condition(not transaction_id.is_empty(), "PersistentCoinTransactionService transaction id cannot be empty.")
	TransactionSourceScript.assert_valid(source)
	Validation.require_condition(source != TransactionSourceScript.Value.PICKUP, "PersistentCoinTransactionService cannot apply pickup transactions.")
	Validation.require_condition(coin_delta != 0, "PersistentCoinTransactionService transaction delta cannot be zero.")

	var typed_wallet_transaction_service: WalletTransactionServiceScript = wallet_transaction_service as WalletTransactionServiceScript
	var transaction: CoinTransactionScript = CoinTransactionScript.new(transaction_id, source, coin_delta)
	return typed_wallet_transaction_service.apply_transaction(wallet, persistent_transaction_ledger, transaction)