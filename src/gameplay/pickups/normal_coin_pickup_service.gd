class_name NormalCoinPickupService
extends RefCounted

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CoinTransactionScript = preload("res://src/economy/coin_transaction.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func resolve(
	socket_id: StringName,
	body: Node,
	player: Node,
	run_session: RefCounted,
	wallet: RefCounted,
	transaction_ledger: RefCounted,
	wallet_transaction_service: RefCounted,
	coin_amount: int
) -> bool:
	Validation.require_condition(not String(socket_id).is_empty(), "NormalCoinPickupService requires a socket id.")
	Validation.require_condition(body != null, "NormalCoinPickupService requires a body.")
	Validation.require_condition(player != null, "NormalCoinPickupService requires a player character.")
	Validation.require_condition(player is PlayerCharacterScript, "NormalCoinPickupService requires a PlayerCharacter implementation.")
	Validation.require_condition(run_session != null, "NormalCoinPickupService requires a run session.")
	Validation.require_condition(run_session is RunSessionScript, "NormalCoinPickupService requires a RunSession implementation.")
	Validation.require_condition(wallet != null, "NormalCoinPickupService requires a wallet.")
	Validation.require_condition(wallet is WalletScript, "NormalCoinPickupService requires a Wallet implementation.")
	Validation.require_condition(transaction_ledger != null, "NormalCoinPickupService requires a transaction ledger.")
	Validation.require_condition(transaction_ledger is CoinTransactionLedgerScript, "NormalCoinPickupService requires a CoinTransactionLedger implementation.")
	Validation.require_condition(wallet_transaction_service != null, "NormalCoinPickupService requires a wallet transaction service.")
	Validation.require_condition(wallet_transaction_service is WalletTransactionServiceScript, "NormalCoinPickupService requires a WalletTransactionService implementation.")
	Validation.require_condition(coin_amount > 0, "NormalCoinPickupService coin amount must be positive.")

	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	if body != typed_player.get_player_body():
		return false

	var typed_run_session: RunSessionScript = run_session as RunSessionScript
	var typed_wallet: WalletScript = wallet as WalletScript
	var typed_transaction_ledger: CoinTransactionLedgerScript = transaction_ledger as CoinTransactionLedgerScript
	var typed_wallet_transaction_service: WalletTransactionServiceScript = wallet_transaction_service as WalletTransactionServiceScript
	var transaction: CoinTransactionScript = CoinTransactionScript.new(
		"%s:%s" % [TransactionSourceScript.to_label(TransactionSourceScript.Value.PICKUP), String(socket_id)],
		TransactionSourceScript.Value.PICKUP,
		coin_amount
	)
	var transaction_applied: bool = typed_wallet_transaction_service.apply_transaction(
		typed_wallet,
		typed_transaction_ledger,
		transaction
	)
	if not transaction_applied:
		return false

	typed_run_session.add_run_earned_coins(coin_amount)
	return true