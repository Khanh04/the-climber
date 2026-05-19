extends GutTest

const AppSettingsSnapshotScript = preload("res://src/platform/storage/app_settings_snapshot.gd")
const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticInventoryScript = preload("res://src/cosmetics/cosmetic_inventory.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticPurchaseOutcomeScript = preload("res://src/cosmetics/cosmetic_purchase_outcome.gd")
const CosmeticPurchaseResultScript = preload("res://src/cosmetics/cosmetic_purchase_result.gd")
const PauseMenuStateScript = preload("res://src/ui/pause_menu_state.gd")
const RunOverlayRuntimeScript = preload("res://src/ui/run_overlay_runtime.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const SettingsPresenterScript = preload("res://src/ui/settings_presenter.gd")
const SettingsStateScript = preload("res://src/ui/settings_state.gd")
const StorePresenterScript = preload("res://src/ui/store_presenter.gd")
const StoreStateScript = preload("res://src/ui/store_state.gd")
const CosmeticLoadoutServiceScript = preload("res://src/cosmetics/cosmetic_loadout_service.gd")
const WalletScript = preload("res://src/economy/wallet.gd")

func test_pause_menu_visibility_transitions_and_state_snapshot() -> void:
	var runtime: RunOverlayRuntimeScript = RunOverlayRuntimeScript.new()
	var run_session: RunSessionScript = RunSessionScript.new()
	var wallet: WalletScript = WalletScript.new(12)

	assert_false(runtime.is_pause_menu_visible())
	assert_false(runtime.show_pause_menu(RunStateScript.Value.ENDED))
	assert_false(runtime.is_pause_menu_visible())
	assert_true(runtime.show_pause_menu(RunStateScript.Value.CLIMBING))
	assert_true(runtime.is_pause_menu_visible())

	var pause_state: PauseMenuStateScript = runtime.build_pause_menu_state(run_session, wallet)
	assert_true(pause_state.visible)
	assert_eq(pause_state.wallet_coins, 12)
	assert_true(runtime.resume_from_pause_menu())
	assert_false(runtime.is_pause_menu_visible())

func test_build_settings_state_uses_presenter_snapshot() -> void:
	var runtime: RunOverlayRuntimeScript = RunOverlayRuntimeScript.new()
	var presenter: SettingsPresenterScript = SettingsPresenterScript.new()
	var snapshot: AppSettingsSnapshotScript = AppSettingsSnapshotScript.new(1, true, 0.25, false, 0.35, 0.1)

	var state: SettingsStateScript = runtime.build_settings_state(presenter, snapshot, true)
	assert_true(state.visible)
	assert_true(state.audio_muted)
	assert_eq(state.master_volume_ratio, 0.25)
	assert_false(state.haptics_enabled)
	assert_eq(state.touch_split_ratio, 0.35)
	assert_eq(state.touch_center_dead_zone_ratio, 0.1)

func test_store_selection_and_feedback_flow_updates_built_store_state() -> void:
	var runtime: RunOverlayRuntimeScript = RunOverlayRuntimeScript.new()
	var loadout_service: CosmeticLoadoutServiceScript = CosmeticLoadoutServiceScript.new()
	var store_presenter: StorePresenterScript = StorePresenterScript.new(loadout_service)
	var catalog: CosmeticItemCatalogScript = load("res://resources/config/cosmetic_item_catalog.tres") as CosmeticItemCatalogScript
	var inventory: CosmeticInventoryScript = CosmeticInventoryScript.new(PackedStringArray(["body_sunrise_jacket"]), catalog.get_default_unlocked_item_ids())
	var loadout: CosmeticLoadoutScript = CosmeticLoadoutScript.new()
	var wallet: WalletScript = WalletScript.new(28)
	var purchase_result: CosmeticPurchaseResultScript = CosmeticPurchaseResultScript.new(
		&"body_sunrise_jacket",
		CosmeticPurchaseOutcomeScript.Value.PURCHASED,
		28
	)

	runtime.select_store_item(&"body_sunrise_jacket")
	var selected_state: StoreStateScript = runtime.build_store_state(store_presenter, catalog, inventory, loadout, wallet)
	assert_eq(selected_state.selected_item_id, &"body_sunrise_jacket")
	assert_eq(selected_state.feedback_message, "")

	runtime.record_purchase_result(purchase_result, catalog)
	var purchased_state: StoreStateScript = runtime.build_store_state(store_presenter, catalog, inventory, loadout, wallet)
	assert_eq(purchased_state.selected_item_id, &"body_sunrise_jacket")
	assert_eq(purchased_state.feedback_message, "Unlocked Sunrise Jacket.")

	runtime.record_equipped_item(&"body_sunrise_jacket", catalog)
	var equipped_state: StoreStateScript = runtime.build_store_state(store_presenter, catalog, inventory, loadout, wallet)
	assert_eq(equipped_state.feedback_message, "Equipped Sunrise Jacket.")

	runtime.clear_store_feedback()
	var cleared_state: StoreStateScript = runtime.build_store_state(store_presenter, catalog, inventory, loadout, wallet)
	assert_eq(cleared_state.feedback_message, "")