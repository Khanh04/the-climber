class_name StorePresenter
extends RefCounted

const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticItemScript = preload("res://resources/config/cosmetic_item.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const StoreItemStateScript = preload("res://src/ui/store_item_state.gd")
const StoreStateScript = preload("res://src/ui/store_state.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

var _loadout_service: CosmeticLoadoutServiceScript

func _init(loadout_service: RefCounted) -> void:
	Validation.require_condition(loadout_service != null, "StorePresenter requires a loadout service.")
	Validation.require_condition(loadout_service is CosmeticLoadoutServiceScript, "StorePresenter requires a CosmeticLoadoutService implementation.")
	_loadout_service = loadout_service as CosmeticLoadoutServiceScript

func build_state(
	catalog: Resource,
	inventory: RefCounted,
	loadout: Resource,
	wallet: RefCounted,
	selected_item_id: StringName = StringName(),
	feedback_message: String = ""
) -> StoreStateScript:
	var typed_catalog: CosmeticItemCatalogScript = _require_catalog(catalog)
	var typed_inventory: CosmeticInventoryScript = _require_inventory(inventory)
	var typed_loadout: CosmeticLoadoutScript = _require_loadout(loadout)
	var typed_wallet: WalletScript = _require_wallet(wallet)
	_loadout_service.assert_loadout_matches_catalog(typed_loadout, typed_catalog)

	var item_states: Array[StoreItemStateScript] = []
	var resolved_selected_item_id: StringName = selected_item_id
	var catalog_items: Array[CosmeticItemScript] = typed_catalog.get_all_items()
	if resolved_selected_item_id.is_empty():
		resolved_selected_item_id = catalog_items[0].item_id
	else:
		var _selected_item: CosmeticItemScript = typed_catalog.get_required_item_by_id(resolved_selected_item_id)

	for item: CosmeticItemScript in catalog_items:
		var owned: bool = typed_inventory.is_owned(item.item_id)
		var equipped: bool = _loadout_service.is_item_equipped(typed_loadout, item)
		var can_purchase: bool = not owned and item.price_coins > 0 and typed_wallet.get_coins() >= item.price_coins
		var can_equip: bool = owned and not equipped
		item_states.append(StoreItemStateScript.new(
			item.item_id,
			item.display_name,
			item.slot,
			item.price_coins,
			owned,
			equipped,
			can_purchase,
			can_equip
		))

	var store_state: StoreStateScript = StoreStateScript.new(typed_wallet.get_coins(), item_states, resolved_selected_item_id, feedback_message)
	store_state.assert_valid()
	return store_state

func _require_catalog(catalog: Resource) -> CosmeticItemCatalogScript:
	Validation.require_condition(catalog != null, "StorePresenter requires a cosmetic item catalog.")
	Validation.require_condition(catalog is CosmeticItemCatalogScript, "StorePresenter requires a CosmeticItemCatalog resource.")
	var typed_catalog: CosmeticItemCatalogScript = catalog as CosmeticItemCatalogScript
	typed_catalog.assert_valid()
	return typed_catalog

func _require_inventory(inventory: RefCounted) -> CosmeticInventoryScript:
	Validation.require_condition(inventory != null, "StorePresenter requires a cosmetic inventory.")
	Validation.require_condition(inventory is CosmeticInventoryScript, "StorePresenter requires a CosmeticInventory implementation.")
	return inventory as CosmeticInventoryScript

func _require_loadout(loadout: Resource) -> CosmeticLoadoutScript:
	Validation.require_condition(loadout != null, "StorePresenter requires a cosmetic loadout.")
	Validation.require_condition(loadout is CosmeticLoadoutScript, "StorePresenter requires a CosmeticLoadout resource.")
	var typed_loadout: CosmeticLoadoutScript = loadout as CosmeticLoadoutScript
	typed_loadout.assert_valid()
	return typed_loadout

func _require_wallet(wallet: RefCounted) -> WalletScript:
	Validation.require_condition(wallet != null, "StorePresenter requires a wallet.")
	Validation.require_condition(wallet is WalletScript, "StorePresenter requires a Wallet implementation.")
	return wallet as WalletScript