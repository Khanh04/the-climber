extends GutTest

const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")
const CosmeticUnlockPurchaseServiceScript = preload("res://src/cosmetics/cosmetic_unlock_purchase_service.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const PlayerAppearanceScript = preload("res://resources/config/player_appearance.gd")
const PlayerAppearanceCatalogScript = preload("res://resources/config/player_appearance_catalog.gd")
const StoreItemStateScript = preload("res://src/ui/store_item_state.gd")
const StorePresenterScript = preload("res://src/ui/store_presenter.gd")
const StoreStateScript = preload("res://src/ui/store_state.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")

func test_default_cosmetic_item_catalog_is_valid() -> void:
    var catalog: CosmeticItemCatalogScript = _load_catalog()

    assert_true(catalog.is_valid())
    assert_eq(catalog.get_required_player_appearance_item_by_id(&"human").item_id, &"character_human")
    assert_eq(catalog.get_required_item_by_id(&"body_sunrise_jacket").slot, CosmeticSlotScript.Value.BODY)
    assert_eq(catalog.get_required_chaser_item_by_theme_id(&"glitch").item_id, &"chaser_glitch")
    assert_true(catalog.get_default_unlocked_item_ids().has("character_human"))
    assert_true(catalog.get_default_unlocked_item_ids().has("body_default"))
    assert_true(catalog.get_default_unlocked_item_ids().has("chaser_rising_void"))

func test_default_player_appearance_catalog_is_valid() -> void:
    var catalog: PlayerAppearanceCatalogScript = _load_appearance_catalog()
    var human_appearance: PlayerAppearanceScript = catalog.get_required_appearance_by_id(&"human")

    assert_true(catalog.is_valid())
    assert_eq(human_appearance.display_name, "Human")
    assert_eq(human_appearance.left_upper_arm_texture_path, "res://assets/PNG/Character/CHR2/leftarm.png")
    assert_eq(human_appearance.right_upper_arm_texture_path, "res://assets/PNG/Character/CHR2/rightarm.png")
    assert_eq(human_appearance.face_texture_path, "res://assets/PNG/Character/CHR2/head.png")

func test_cosmetic_inventory_merges_defaults_and_saved_ids_without_duplicates() -> void:
    var catalog: CosmeticItemCatalogScript = _load_catalog()
    var inventory := CosmeticInventoryScript.new(PackedStringArray(["body_sunrise_jacket", "body_default"]), catalog.get_default_unlocked_item_ids())

    assert_true(inventory.is_owned(&"body_default"))
    assert_true(inventory.is_owned(&"body_sunrise_jacket"))
    assert_eq(inventory.get_owned_item_ids().count("body_default"), 1)

func test_cosmetic_loadout_service_equips_owned_player_and_chaser_items() -> void:
    var catalog: CosmeticItemCatalogScript = _load_catalog()
    var inventory := CosmeticInventoryScript.new(PackedStringArray(["body_sunrise_jacket", "chaser_hot_coffee"]), catalog.get_default_unlocked_item_ids())
    var loadout := CosmeticLoadoutScript.new()
    var service := CosmeticLoadoutServiceScript.new()

    service.equip_item(loadout, inventory, catalog, &"character_human")
    service.equip_item(loadout, inventory, catalog, &"body_sunrise_jacket")
    service.equip_item(loadout, inventory, catalog, &"chaser_hot_coffee")

    assert_eq(loadout.player_appearance_id, &"human")
    assert_eq(loadout.body_cosmetic_id, &"body_sunrise_jacket")
    assert_eq(loadout.chaser_theme_id, &"hot_coffee")
    service.assert_loadout_owned(loadout, inventory, catalog)

func test_cosmetic_unlock_purchase_spends_wallet_once_and_unlocks_item() -> void:
    var catalog: CosmeticItemCatalogScript = _load_catalog()
    var inventory := CosmeticInventoryScript.new(PackedStringArray(), catalog.get_default_unlocked_item_ids())
    var wallet := WalletScript.new(20)
    var ledger := CoinTransactionLedgerScript.new()
    var wallet_service := WalletTransactionServiceScript.new()
    var persistent_service := PersistentCoinTransactionServiceScript.new()
    var purchase_service := CosmeticUnlockPurchaseServiceScript.new()

    var result: CosmeticPurchaseResultScript = purchase_service.purchase_item(
        wallet,
        inventory,
        catalog,
        ledger,
        wallet_service,
        persistent_service,
        &"body_sunrise_jacket"
    )

    assert_eq(result.outcome, CosmeticPurchaseOutcomeScript.Value.PURCHASED)
    assert_eq(wallet.get_coins(), 8)
    assert_true(inventory.is_owned(&"body_sunrise_jacket"))
    assert_true(ledger.has_transaction_id("purchase:cosmetic_unlock:body_sunrise_jacket"))

    var duplicate_result: CosmeticPurchaseResultScript = purchase_service.purchase_item(
        wallet,
        inventory,
        catalog,
        ledger,
        wallet_service,
        persistent_service,
        &"body_sunrise_jacket"
    )

    assert_eq(duplicate_result.outcome, CosmeticPurchaseOutcomeScript.Value.ALREADY_OWNED)
    assert_eq(wallet.get_coins(), 8)

func test_cosmetic_unlock_purchase_reports_insufficient_funds_without_unlocking() -> void:
    var catalog: CosmeticItemCatalogScript = _load_catalog()
    var inventory := CosmeticInventoryScript.new(PackedStringArray(), catalog.get_default_unlocked_item_ids())
    var wallet := WalletScript.new(2)
    var ledger := CoinTransactionLedgerScript.new()
    var wallet_service := WalletTransactionServiceScript.new()
    var persistent_service := PersistentCoinTransactionServiceScript.new()
    var purchase_service := CosmeticUnlockPurchaseServiceScript.new()

    var result: CosmeticPurchaseResultScript = purchase_service.purchase_item(
        wallet,
        inventory,
        catalog,
        ledger,
        wallet_service,
        persistent_service,
        &"chaser_hot_coffee"
    )

    assert_eq(result.outcome, CosmeticPurchaseOutcomeScript.Value.INSUFFICIENT_FUNDS)
    assert_eq(wallet.get_coins(), 2)
    assert_false(inventory.is_owned(&"chaser_hot_coffee"))
    assert_false(ledger.get_transaction_ids().has("purchase:cosmetic_unlock:chaser_hot_coffee"))

func test_store_presenter_marks_owned_equipped_and_affordable_items() -> void:
    var catalog: CosmeticItemCatalogScript = _load_catalog()
    var inventory := CosmeticInventoryScript.new(PackedStringArray(["body_sunrise_jacket"]), catalog.get_default_unlocked_item_ids())
    var loadout := CosmeticLoadoutScript.new()
    loadout.player_appearance_id = &"human"
    loadout.body_cosmetic_id = &"body_sunrise_jacket"
    var wallet := WalletScript.new(20)
    var loadout_service := CosmeticLoadoutServiceScript.new()
    var presenter := StorePresenterScript.new(loadout_service)

    var state: StoreStateScript = presenter.build_state(catalog, inventory, loadout, wallet, &"chaser_hot_coffee")

    assert_eq(state.wallet_coins, 20)
    assert_eq(state.selected_item_id, &"chaser_hot_coffee")
    assert_true(_find_item_state(state, &"character_human").owned)
    assert_true(_find_item_state(state, &"character_human").equipped)
    assert_true(_find_item_state(state, &"body_sunrise_jacket").owned)
    assert_true(_find_item_state(state, &"body_sunrise_jacket").equipped)
    assert_true(_find_item_state(state, &"chaser_hot_coffee").can_purchase)
    assert_false(_find_item_state(state, &"chaser_hot_coffee").owned)

func _load_catalog() -> CosmeticItemCatalogScript:
    var catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript

    assert_not_null(catalog)
    return catalog

func _load_appearance_catalog() -> PlayerAppearanceCatalogScript:
    var catalog: PlayerAppearanceCatalogScript = load("res://resources/config/player_appearance_catalog.tres") as PlayerAppearanceCatalogScript

    assert_not_null(catalog)
    return catalog

func _find_item_state(state: StoreStateScript, item_id: StringName) -> StoreItemStateScript:
    for item in state.items:
        if item.item_id == item_id:
            return item

    return null