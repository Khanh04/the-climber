class_name WalletTransactionService
extends RefCounted

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CoinTransactionScript = preload("res://src/economy/coin_transaction.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

func apply_transaction(wallet: RefCounted, transaction_ledger: RefCounted, transaction: RefCounted) -> bool:
	Validation.require_condition(wallet != null, "WalletTransactionService requires a wallet.")
	Validation.require_condition(wallet is WalletScript, "WalletTransactionService requires a Wallet implementation.")
	Validation.require_condition(transaction_ledger != null, "WalletTransactionService requires a transaction ledger.")
	Validation.require_condition(transaction_ledger is CoinTransactionLedgerScript, "WalletTransactionService requires a CoinTransactionLedger implementation.")
	Validation.require_condition(transaction != null, "WalletTransactionService requires a coin transaction.")
	Validation.require_condition(transaction is CoinTransactionScript, "WalletTransactionService requires a CoinTransaction implementation.")

	var typed_wallet: WalletScript = wallet as WalletScript
	var typed_transaction_ledger: CoinTransactionLedgerScript = transaction_ledger as CoinTransactionLedgerScript
	var typed_transaction: CoinTransactionScript = transaction as CoinTransactionScript
	typed_transaction.assert_valid()

	if typed_transaction_ledger.has_transaction_id(typed_transaction.transaction_id):
		return false

	if typed_transaction.is_grant():
		typed_wallet.grant_coins(typed_transaction.coin_delta)
	else:
		typed_wallet.spend_coins(-typed_transaction.coin_delta)

	var was_recorded: bool = typed_transaction_ledger.record_transaction_id(typed_transaction.transaction_id)
	Validation.require_condition(was_recorded, "WalletTransactionService requires a new transaction id after applying a transaction.")
	return true