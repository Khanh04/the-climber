extends GutTest

func test_wallet_banks_normal_coin_pickups_immediately() -> void:
    var wallet: Wallet = Wallet.new()

    wallet.grant_coins(12)

    assert_eq(wallet.get_coins(), 12)

func test_wallet_spends_from_banked_balance() -> void:
    var wallet: Wallet = Wallet.new(20)

    wallet.spend_coins(7)

    assert_eq(wallet.get_coins(), 13)