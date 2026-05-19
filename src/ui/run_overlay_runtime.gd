class_name RunOverlayRuntime
extends RefCounted

const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const PauseMenuStateScript = preload("res://src/ui/pause_menu_state.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const SettingsPresenterScript = preload("res://src/ui/settings_presenter.gd")
const SettingsStateScript = preload("res://src/ui/settings_state.gd")
const StorePresenterScript = preload("res://src/ui/store_presenter.gd")
const StoreStateScript = preload("res://src/ui/store_state.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

var _pause_menu_visible: bool = false
var _store_selected_item_id: StringName = StringName()
var _store_feedback_message: String = ""

func is_pause_menu_visible() -> bool:
	return _pause_menu_visible

func show_pause_menu(run_state: int) -> bool:
	RunStateScript.assert_valid(run_state)
	if run_state == RunStateScript.Value.ENDED:
		return false
	_pause_menu_visible = true
	return true

func hide_pause_menu() -> void:
	_pause_menu_visible = false

func resume_from_pause_menu() -> bool:
	if not _pause_menu_visible:
		return false
	_pause_menu_visible = false
	return true

func build_pause_menu_state(run_session: RunSessionScript, wallet: WalletScript) -> PauseMenuStateScript:
	Validation.require_condition(run_session != null, "RunOverlayRuntime requires a run session to build pause menu state.")
	Validation.require_condition(wallet != null, "RunOverlayRuntime requires a wallet to build pause menu state.")
	return PauseMenuStateScript.new(
		_pause_menu_visible,
		run_session.get_height_meters(),
		wallet.get_coins(),
		run_session.get_run_earned_coins()
	)

func build_settings_state(
	settings_presenter: SettingsPresenterScript,
	app_settings_snapshot: AppSettingsSnapshotScript,
	settings_visible: bool
) -> SettingsStateScript:
	Validation.require_condition(settings_presenter != null, "RunOverlayRuntime requires a settings presenter to build settings state.")
	Validation.require_condition(app_settings_snapshot != null, "RunOverlayRuntime requires app settings to build settings state.")
	return settings_presenter.build_state(app_settings_snapshot, settings_visible)

func build_store_state(
	store_presenter: StorePresenterScript,
	cosmetic_item_catalog: CosmeticItemCatalogScript,
	cosmetic_inventory: RefCounted,
	cosmetic_loadout: Resource,
	wallet: WalletScript
) -> StoreStateScript:
	Validation.require_condition(store_presenter != null, "RunOverlayRuntime requires a store presenter to build store state.")
	Validation.require_condition(cosmetic_item_catalog != null, "RunOverlayRuntime requires a cosmetic item catalog to build store state.")
	Validation.require_condition(wallet != null, "RunOverlayRuntime requires a wallet to build store state.")
	return store_presenter.build_state(
		cosmetic_item_catalog,
		cosmetic_inventory,
		cosmetic_loadout,
		wallet,
		_store_selected_item_id,
		_store_feedback_message
	)

func select_store_item(item_id: StringName) -> void:
	Validation.require_condition(not item_id.is_empty(), "RunOverlayRuntime selected store item id cannot be empty.")
	_store_selected_item_id = item_id
	_store_feedback_message = ""

func record_purchase_result(result: CosmeticPurchaseResultScript, cosmetic_item_catalog: CosmeticItemCatalogScript) -> void:
	Validation.require_condition(result != null, "RunOverlayRuntime requires a cosmetic purchase result.")
	Validation.require_condition(cosmetic_item_catalog != null, "RunOverlayRuntime requires a cosmetic item catalog to record purchase feedback.")
	result.assert_valid()
	_store_selected_item_id = result.item_id
	var item_display_name: String = cosmetic_item_catalog.get_required_item_by_id(result.item_id).display_name
	match result.outcome:
		CosmeticPurchaseOutcomeScript.Value.PURCHASED:
			_store_feedback_message = "Unlocked %s." % item_display_name
		CosmeticPurchaseOutcomeScript.Value.ALREADY_OWNED:
			_store_feedback_message = "%s is already owned." % item_display_name
		CosmeticPurchaseOutcomeScript.Value.INSUFFICIENT_FUNDS:
			_store_feedback_message = "Not enough coins for %s." % item_display_name
		_:
			Validation.require_condition(false, "RunOverlayRuntime requires a supported cosmetic purchase outcome.")

func record_equipped_item(item_id: StringName, cosmetic_item_catalog: CosmeticItemCatalogScript) -> void:
	Validation.require_condition(not item_id.is_empty(), "RunOverlayRuntime equipped store item id cannot be empty.")
	Validation.require_condition(cosmetic_item_catalog != null, "RunOverlayRuntime requires a cosmetic item catalog to record equip feedback.")
	_store_selected_item_id = item_id
	_store_feedback_message = "Equipped %s." % cosmetic_item_catalog.get_required_item_by_id(item_id).display_name

func clear_store_feedback() -> void:
	_store_feedback_message = ""