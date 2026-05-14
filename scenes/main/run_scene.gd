class_name RunScene
extends Node2D

const ChaserContactServiceScript = preload("res://src/gameplay/chaser/chaser_contact_service.gd")
const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ChaserThemeCatalogScript = preload("res://resources/config/chaser_theme_catalog.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const CoinTransactionLedgerScript = preload("res://src/economy/coin_transaction_ledger.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const DailyChunkGeneratorScript = preload("res://src/gameplay/generation/daily_chunk_generator.gd")
const DesktopDebugInputAdapterScript = preload("res://src/gameplay/player/desktop_debug_input_adapter.gd")
const GeneratedCoinPickupSpawnAdapterScript = preload("res://src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd")
const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const GeneratedChunkSceneBuilderScript = preload("res://src/gameplay/generation/generated_chunk_scene_builder.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const LethalHazardContactServiceScript = preload("res://src/gameplay/hazards/lethal_hazard_contact_service.gd")
const MobileTouchInputAdapterScript = preload("res://src/gameplay/player/mobile_touch_input_adapter.gd")
const NormalCoinPickupServiceScript = preload("res://src/gameplay/pickups/normal_coin_pickup_service.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")
const PersistentCoinTransactionServiceScript = preload("res://src/economy/persistent_coin_transaction_service.gd")
const PostRunCoinDoublerGrantServiceScript = preload("res://src/economy/post_run_coin_doubler_grant_service.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const RewardedAdsAdapterScript = preload("res://src/platform/ads/rewarded_ads_adapter.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const BottomScreenFallServiceScript = preload("res://src/gameplay/run/bottom_screen_fall_service.gd")
const JsonFileLocalStorageAdapterScript = preload("res://src/platform/storage/json_file_local_storage_adapter.gd")
const LocalStorageAdapterScript = preload("res://src/platform/storage/local_storage_adapter.gd")
const RunLoopCoordinatorScript = preload("res://src/gameplay/run/run_loop_coordinator.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")
const StaminaFallServiceScript = preload("res://src/gameplay/run/stamina_fall_service.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const UnavailableRewardedAdsAdapterScript = preload("res://src/platform/ads/unavailable_rewarded_ads_adapter.gd")
const UtcDateProviderScript = preload("res://src/platform/clock/utc_date_provider.gd")
const SystemUtcDateProviderScript = preload("res://src/platform/clock/system_utc_date_provider.gd")
const RunUiPresenterScript = preload("res://src/ui/run_ui_presenter.gd")
const RunUiViewScript = preload("res://src/ui/run_ui_view.gd")
const WalletScript = preload("res://src/economy/wallet.gd")
const WalletTransactionServiceScript = preload("res://src/economy/wallet_transaction_service.gd")
const WindGustHazardContactServiceScript = preload("res://src/gameplay/hazards/wind_gust_hazard_contact_service.gd")

@export var climb_tuning: ClimbPrototypeTuningScript
@export var stamina_tuning: StaminaTuningScript
@export var generation_tuning: GenerationTuningScript
@export var cosmetic_loadout: CosmeticLoadoutScript
@export var chaser_theme_catalog: ChaserThemeCatalogScript

@onready var _player: PlayerCharacterScript = %PlayerCharacter
@onready var _chaser_kill_zone: ChaserKillZoneScript = get_node("ChaserKillZone") as ChaserKillZoneScript
@onready var _generated_chunk_coordinator: GeneratedChunkCoordinatorScript = %GeneratedChunks
@onready var _reset_anchor: Marker2D = %ResetAnchor
@onready var _camera: Camera2D = %DevCamera
@onready var _starter_handholds_root: Node2D = get_node("Handholds") as Node2D
@onready var _run_hud: Control = %RunHud
@onready var _run_end_screen: Control = %RunEndScreen
@onready var _run_ui_view = RunUiViewScript.new(_run_hud, _run_end_screen)

var _run_session: RunSessionScript = RunSessionScript.new()
var _stamina: StaminaRuntimeScript
var _desktop_input: DesktopDebugInputAdapterScript = DesktopDebugInputAdapterScript.new()
var _mobile_input: MobileTouchInputAdapterScript = MobileTouchInputAdapterScript.new()
var _controller: ClimbPrototypeControllerScript
var _chaser_contact_service: ChaserContactServiceScript = ChaserContactServiceScript.new()
var _chaser_pacing_model: ChaserPacingModelScript
var _bottom_screen_fall_service: BottomScreenFallServiceScript = BottomScreenFallServiceScript.new()
var _lethal_hazard_contact_service: LethalHazardContactServiceScript = LethalHazardContactServiceScript.new()
var _normal_coin_pickup_service: NormalCoinPickupServiceScript = NormalCoinPickupServiceScript.new()
var _run_loop_coordinator: RunLoopCoordinatorScript = RunLoopCoordinatorScript.new()
var _run_ui_presenter: RunUiPresenterScript = RunUiPresenterScript.new(_run_loop_coordinator)
var _stamina_fall_service: StaminaFallServiceScript = StaminaFallServiceScript.new()
var _wind_gust_hazard_contact_service: WindGustHazardContactServiceScript = WindGustHazardContactServiceScript.new()
var _wallet: WalletScript = WalletScript.new()
var _rewarded_ads_adapter: RewardedAdsAdapterScript = UnavailableRewardedAdsAdapterScript.new()
var _persistent_coin_transaction_service: PersistentCoinTransactionServiceScript = PersistentCoinTransactionServiceScript.new()
var _post_run_coin_doubler_grant_service: PostRunCoinDoublerGrantServiceScript = PostRunCoinDoublerGrantServiceScript.new()
var _wallet_transaction_service: WalletTransactionServiceScript = WalletTransactionServiceScript.new()
var _persistent_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
var _run_pickup_transaction_ledger: CoinTransactionLedgerScript = CoinTransactionLedgerScript.new()
var _active_touch_positions: PackedVector2Array = PackedVector2Array()
var _left_aim_preview: Line2D = null
var _right_aim_preview: Line2D = null
var _aim_target_marker: Polygon2D = null
var _debug_reset_pressed: bool = false
var _save_snapshot: SaveSnapshotScript = null
var _local_storage_adapter: LocalStorageAdapterScript = null
var _save_storage: SaveStorageScript = null
var _post_run_coin_doubler_reward_id: String = ""
var _start_y: float = 0.0
var utc_date_provider: UtcDateProviderScript = SystemUtcDateProviderScript.new()

func _ready() -> void:
	_validate_required_state()
	_initialize_save_storage()
	_load_or_create_save_state()
	cosmetic_loadout = _duplicate_cosmetic_loadout(cosmetic_loadout)
	_apply_saved_cosmetic_selection()
	var _connect_result: int = _run_end_screen.connect(&"restart_requested", _on_run_end_restart_requested)
	var _post_run_coin_doubler_connect_result: int = _run_end_screen.connect(&"post_run_coin_doubler_requested", _on_post_run_coin_doubler_requested)
	var _chaser_connect_result: int = _chaser_kill_zone.connect(&"chaser_contacted", _on_chaser_contacted)
	_player.set_climb_tuning(climb_tuning)
	_stamina = StaminaRuntimeScript.new(stamina_tuning)
	_controller = ClimbPrototypeControllerScript.new(climb_tuning, _stamina)
	_chaser_pacing_model = ChaserPacingModelScript.new(_chaser_kill_zone.chaser_tuning)
	_apply_equipped_chaser_theme()
	_start_y = _reset_anchor.global_position.y
	_configure_generated_chunks()
	_reset_playground()
	_refresh_ui()

func set_local_storage_adapter(local_storage_adapter: RefCounted) -> void:
	Validation.require_condition(local_storage_adapter != null, "RunScene requires a local storage adapter.")
	Validation.require_condition(local_storage_adapter is LocalStorageAdapterScript, "RunScene requires a LocalStorageAdapter implementation.")
	_local_storage_adapter = local_storage_adapter as LocalStorageAdapterScript
	if not is_node_ready():
		return

	_initialize_save_storage()
	if _save_snapshot == null:
		_load_or_create_save_state()
		_apply_saved_cosmetic_selection()
		_apply_equipped_chaser_theme()
		_refresh_ui()

func set_rewarded_ads_adapter(rewarded_ads_adapter: RefCounted) -> void:
	Validation.require_condition(rewarded_ads_adapter != null, "RunScene requires a rewarded ads adapter.")
	Validation.require_condition(rewarded_ads_adapter is RewardedAdsAdapterScript, "RunScene requires a RewardedAdsAdapter implementation.")
	_rewarded_ads_adapter = rewarded_ads_adapter as RewardedAdsAdapterScript
	if not is_node_ready():
		return

	_refresh_ui()

func set_save_snapshot(snapshot: RefCounted) -> void:
	Validation.require_condition(snapshot != null, "RunScene requires a save snapshot.")
	Validation.require_condition(snapshot is SaveSnapshotScript, "RunScene requires a SaveSnapshot implementation.")
	var typed_snapshot: SaveSnapshotScript = snapshot as SaveSnapshotScript
	typed_snapshot.assert_valid()
	_save_snapshot = typed_snapshot
	_hydrate_runtime_save_state_from_snapshot()
	if not is_node_ready():
		return

	_apply_saved_cosmetic_selection()
	_apply_equipped_chaser_theme()
	_refresh_ui()

func set_utc_date_provider(date_provider: RefCounted) -> void:
	Validation.require_condition(date_provider != null, "RunScene requires a UTC date provider.")
	Validation.require_condition(date_provider is UtcDateProviderScript, "RunScene requires a UtcDateProvider implementation.")
	utc_date_provider = date_provider as UtcDateProviderScript
	if not is_node_ready():
		return

	_configure_generated_chunks()
	_reset_playground()
	_refresh_ui()

func _physics_process(delta: float) -> void:
	if _consume_debug_reset_input():
		_reset_playground()
		_refresh_ui()
		return

	var input_frame: PlayerInputFrameScript = _create_input_frame()
	_update_camera_follow()
	_sync_generated_chunks()
	_update_chaser(delta)

	if _resolve_bottom_screen_fall_if_needed():
		_clear_aim_preview()
		_refresh_ui()
		return

	if _run_session.get_state() != RunStateScript.Value.CLIMBING:
		_clear_aim_preview()
		_refresh_ui()
		return

	var left_target: RefCounted = _find_nearest_handhold(_player.get_left_hand_anchor_global_position())
	var right_target: RefCounted = _find_nearest_handhold(_player.get_right_hand_anchor_global_position())
	var result: ClimbPrototypeFrameResultScript = _controller.apply_input_frame(input_frame, left_target, right_target, delta)

	_player.apply_frame_motion(result, _controller.get_attachment_state())
	_sync_aim_preview(input_frame)
	_record_height()

	if result.stamina_depleted_now:
		var stamina_fall_service: Object = _stamina_fall_service
		stamina_fall_service.call("resolve", _player, _run_session)
		_clear_aim_preview()

	_refresh_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_reset_run"):
		_reset_playground()
		_refresh_ui()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		_update_touch_position(event as InputEventScreenTouch)

func reset_for_test() -> void:
	_reset_playground()

func get_run_session_for_test() -> RunSessionScript:
	return _run_session

func get_wallet_for_test() -> WalletScript:
	return _wallet

func apply_persistent_coin_transaction(transaction_id: String, source: int, coin_delta: int) -> bool:
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before applying persistent coin transactions.")
	var transaction_applied: bool = _persistent_coin_transaction_service.apply_persistent_transaction(
		_wallet,
		_persistent_transaction_ledger,
		_wallet_transaction_service,
		transaction_id,
		source,
		coin_delta
	)
	if not transaction_applied:
		return false

	_persist_save_state()
	_refresh_ui()
	return true

func apply_post_run_coin_doubler_reward(rewarded_ad_result: RefCounted, reward_id: String) -> bool:
	Validation.require_condition(rewarded_ad_result != null, "RunScene requires a rewarded ad result for post-run coin doubling.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "RunScene requires a RewardedAdResult implementation for post-run coin doubling.")
	Validation.require_condition(_run_session.get_state() == RunStateScript.Value.ENDED, "RunScene can only apply post-run coin doubler rewards after the run has ended.")
	Validation.require_condition(_run_session.get_run_earned_coins() > 0, "RunScene requires positive run-earned coins before applying post-run coin doubler rewards.")
	var bound_reward_id: String = _bind_post_run_coin_doubler_reward_id(reward_id)

	var reward_applied: bool = _post_run_coin_doubler_grant_service.apply_reward(
		_wallet,
		_persistent_transaction_ledger,
		_wallet_transaction_service,
		_persistent_coin_transaction_service,
		rewarded_ad_result,
		bound_reward_id,
		_run_session.get_run_earned_coins()
	)
	if not reward_applied:
		return false

	_persist_save_state()
	_refresh_ui()
	return true

func get_controller_for_test() -> ClimbPrototypeControllerScript:
	return _controller

func get_player_for_test() -> PlayerCharacterScript:
	return _player

func get_player_body_for_test() -> RigidBody2D:
	return _player.get_player_body()

func get_left_hand_anchor_for_test() -> Marker2D:
	return _player.get_left_hand_anchor()

func get_right_hand_anchor_for_test() -> Marker2D:
	return _player.get_right_hand_anchor()

func get_chaser_for_test() -> ChaserKillZoneScript:
	return _chaser_kill_zone

func get_generated_chunk_coordinator_for_test() -> GeneratedChunkCoordinatorScript:
	return _generated_chunk_coordinator

func get_chaser_feedback_snapshot_for_test() -> ChaserFeedbackSnapshotScript:
	Validation.require_condition(_chaser_pacing_model != null, "RunScene requires a chaser pacing model for feedback snapshots.")
	return _chaser_pacing_model.get_current_feedback_snapshot()

func get_chaser_feedback_intensity_ratio_for_test() -> float:
	Validation.require_condition(_chaser_kill_zone != null, "RunScene requires a chaser kill zone for feedback intensity.")
	return _chaser_kill_zone.get_feedback_intensity_ratio()

func resolve_chaser_contact_for_test() -> void:
	_on_chaser_contacted(_player.get_player_body())

func sync_grip_links_for_test() -> void:
	_player.sync_runtime_grip_links(_controller.get_attachment_state())

func sync_aim_preview_for_test(input_frame: PlayerInputFrameScript) -> void:
	_sync_aim_preview(input_frame)

func get_camera_player_lower_screen_offset_for_test() -> float:
	return _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")

func get_bottom_fall_margin_for_test() -> float:
	return _get_climb_tuning_float(&"bottom_fall_margin_pixels")

func _validate_required_state() -> void:
	Validation.require_condition(climb_tuning != null, "RunScene requires climb tuning.")
	Validation.require_condition(stamina_tuning != null, "RunScene requires stamina tuning.")
	Validation.require_condition(generation_tuning != null, "RunScene requires generation tuning.")
	Validation.require_condition(cosmetic_loadout != null, "RunScene requires a cosmetic loadout.")
	Validation.require_condition(chaser_theme_catalog != null, "RunScene requires a chaser theme catalog.")
	Validation.require_condition(utc_date_provider != null, "RunScene requires a UTC date provider.")
	climb_tuning.assert_valid()
	stamina_tuning.assert_valid()
	generation_tuning.assert_valid()
	cosmetic_loadout.assert_valid()
	chaser_theme_catalog.assert_valid()
	var _equipped_theme = chaser_theme_catalog.get_required_theme_by_id(cosmetic_loadout.chaser_theme_id)
	if _save_snapshot != null:
		_save_snapshot.assert_valid()
		var _saved_theme = chaser_theme_catalog.get_required_theme_by_id(_save_snapshot.chaser_theme_id)
	Validation.require_condition(_player != null, "RunScene requires PlayerCharacter.")
	Validation.require_condition(_chaser_kill_zone != null, "RunScene requires ChaserKillZone.")
	Validation.require_condition(_generated_chunk_coordinator != null, "RunScene requires GeneratedChunks coordinator.")
	Validation.require_condition(_reset_anchor != null, "RunScene requires ResetAnchor.")
	Validation.require_condition(_camera != null, "RunScene requires DevCamera.")
	Validation.require_condition(_starter_handholds_root != null, "RunScene requires Handholds.")
	Validation.require_condition(_run_hud != null, "RunScene requires RunHud.")
	Validation.require_condition(_run_end_screen != null, "RunScene requires RunEndScreen.")
	Validation.require_condition(get_tree().get_nodes_in_group(climb_tuning.handhold_group_name).size() > 0, "RunScene requires at least one handhold.")

func _create_input_frame() -> PlayerInputFrameScript:
	if _active_touch_positions.size() > 0:
		return _mobile_input.create_input_frame(get_viewport_rect().size, _active_touch_positions)

	return _desktop_input.create_input_frame(
		Input.is_action_pressed(&"debug_left_grip"),
		Input.is_action_pressed(&"debug_right_grip"),
		_get_debug_aim_vector(),
		false
	)

func _consume_debug_reset_input() -> bool:
	var reset_pressed_now: bool = Input.is_action_pressed(&"debug_reset_run")
	var should_reset: bool = reset_pressed_now and not _debug_reset_pressed
	_debug_reset_pressed = reset_pressed_now
	return should_reset

func _get_debug_aim_vector() -> Vector2:
	var aim_vector: Vector2 = Vector2.ZERO

	if Input.is_action_pressed(&"debug_aim_left"):
		aim_vector.x -= 1.0

	if Input.is_action_pressed(&"debug_aim_right"):
		aim_vector.x += 1.0

	if Input.is_action_pressed(&"debug_aim_up"):
		aim_vector.y -= 1.0

	return aim_vector

func _update_chaser(delta: float) -> void:
	if _chaser_kill_zone == null or _chaser_pacing_model == null:
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	_chaser_pacing_model.record_height(_calculate_current_height_meters(), delta)
	var feedback_snapshot: ChaserFeedbackSnapshotScript = _chaser_pacing_model.get_current_feedback_snapshot()
	_chaser_kill_zone.sync_feedback(
		feedback_snapshot,
		_player.get_body_global_position().y,
		_get_climb_tuning_float(&"pixels_per_meter")
	)
	_chaser_kill_zone.advance_rise(
		feedback_snapshot.rise_speed_meters_per_second,
		_get_climb_tuning_float(&"pixels_per_meter"),
		delta
	)

func _update_camera_follow() -> void:
	_camera.global_position.y = _run_loop_coordinator.calculate_camera_target_y(
		_camera.global_position.y,
		_player.get_body_global_position().y,
		_get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels"),
		_run_session.get_state()
	)

func _resolve_bottom_screen_fall_if_needed() -> bool:
	var run_loop_coordinator: Object = _run_loop_coordinator
	var should_resolve_bottom_fall: bool = run_loop_coordinator.call(
		"should_resolve_bottom_screen_fall",
		_run_session.get_state(),
		_player.get_body_global_position().y,
		_camera.global_position.y,
		get_viewport_rect().size.y,
		_get_climb_tuning_float(&"bottom_fall_margin_pixels")
	)
	if not should_resolve_bottom_fall:
		return false

	var bottom_screen_fall_service: Object = _bottom_screen_fall_service
	bottom_screen_fall_service.call("resolve", _controller, _player, _run_session)
	return true

func _find_nearest_handhold(anchor_position: Vector2) -> RefCounted:
	var nearest_target: HandholdTargetScript = null
	var nearest_distance: float = climb_tuning.handhold_detection_radius_pixels

	for handhold in get_tree().get_nodes_in_group(climb_tuning.handhold_group_name):
		Validation.require_condition(handhold is Node2D, "RunScene handholds must be Node2D instances.")
		var handhold_node: Node2D = handhold
		var distance: float = anchor_position.distance_to(handhold_node.global_position)

		if distance <= nearest_distance:
			nearest_target = HandholdTargetScript.new(StringName(handhold_node.name), handhold_node.global_position, handhold_node.get_path())
			nearest_distance = distance

	return nearest_target

func _sync_aim_preview(input_frame: PlayerInputFrameScript) -> void:
	if not input_frame.has_aim_intent():
		_clear_aim_preview()
		return

	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	var aim_intent: Object = input_frame.aim_intent
	var aim_vector: Vector2 = aim_intent.get("aim_vector")
	var aim_target_position: Vector2 = _calculate_aim_preview_target_position(aim_vector)
	var left_visible: bool = not attachment_state.is_attached(HandSideScript.Value.LEFT)
	var right_visible: bool = not attachment_state.is_attached(HandSideScript.Value.RIGHT)

	_left_aim_preview = _sync_aim_preview_line(_left_aim_preview, left_visible, _player.get_left_hand_anchor_global_position(), aim_target_position, &"LeftAimPreview")
	_right_aim_preview = _sync_aim_preview_line(_right_aim_preview, right_visible, _player.get_right_hand_anchor_global_position(), aim_target_position, &"RightAimPreview")
	_aim_target_marker = _sync_aim_target_marker(_aim_target_marker, left_visible or right_visible, aim_target_position)

func _calculate_aim_preview_target_position(aim_vector: Vector2) -> Vector2:
	Validation.require_condition(aim_vector != Vector2.ZERO, "Aim preview target requires a non-zero aim vector.")
	var preview_distance: float = maxf(160.0, climb_tuning.handhold_detection_radius_pixels * 1.75)
	var hand_midpoint: Vector2 = (_player.get_left_hand_anchor_global_position() + _player.get_right_hand_anchor_global_position()) * 0.5
	return hand_midpoint + (aim_vector.normalized() * preview_distance)

func _sync_aim_preview_line(current_line: Line2D, should_show: bool, anchor_position: Vector2, target_position: Vector2, line_name: StringName) -> Line2D:
	if not should_show:
		if current_line != null:
			current_line.queue_free()
		return null

	var active_line: Line2D = current_line
	if active_line == null:
		active_line = Line2D.new()
		active_line.name = line_name
		active_line.width = 3.0
		active_line.default_color = Color(1.0, 0.87, 0.47, 0.85)
		add_child(active_line)

	active_line.points = PackedVector2Array([
		to_local(anchor_position),
		to_local(target_position)
	])
	return active_line

func _sync_aim_target_marker(current_marker: Polygon2D, should_show: bool, target_position: Vector2) -> Polygon2D:
	if not should_show:
		if current_marker != null:
			current_marker.queue_free()
		return null

	var active_marker: Polygon2D = current_marker
	if active_marker == null:
		active_marker = Polygon2D.new()
		active_marker.name = &"AimTargetMarker"
		active_marker.color = Color(1.0, 0.95, 0.62, 0.9)
		active_marker.polygon = PackedVector2Array([Vector2(0.0, -8.0), Vector2(8.0, 0.0), Vector2(0.0, 8.0), Vector2(-8.0, 0.0)])
		add_child(active_marker)

	active_marker.global_position = target_position
	return active_marker

func _calculate_current_height_meters() -> float:
	var height_pixels: float = maxf(0.0, _start_y - _player.get_body_global_position().y)
	return height_pixels / _get_climb_tuning_float(&"pixels_per_meter")

func _record_height() -> void:
	_run_session.record_height(_calculate_current_height_meters())

func _configure_generated_chunks() -> void:
	Validation.require_condition(_generated_chunk_coordinator != null, "RunScene requires GeneratedChunks before configuring generated chunks.")
	var pixels_per_meter: float = _get_climb_tuning_float(&"pixels_per_meter")
	var generated_world_origin: Vector2 = _reset_anchor.global_position
	var chunk_start_height_offset_meters: float = 0.0
	var seed_key: String = DailySeedKey.current_utc(utc_date_provider)
	var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(
		pixels_per_meter,
		climb_tuning.handhold_group_name,
		Vector2(128.0, 34.0),
		2,
		0
	)
	var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(generation_tuning)
	_generated_chunk_coordinator.configure(
		generation_tuning,
		generator,
		builder,
		seed_key,
		generated_world_origin,
		chunk_start_height_offset_meters
	)
	if not _generated_chunk_coordinator.chunk_spawned.is_connected(_on_generated_chunk_spawned):
		var _chunk_spawn_connect_result: int = _generated_chunk_coordinator.chunk_spawned.connect(_on_generated_chunk_spawned)

func _sync_generated_chunks() -> void:
	if _generated_chunk_coordinator == null:
		return

	_generated_chunk_coordinator.sync_chunks_for_height(_calculate_current_height_meters(), _collect_attached_hold_paths())

func _collect_attached_hold_paths() -> Array[NodePath]:
	var hold_paths: Array[NodePath] = []
	if _controller == null:
		return hold_paths

	var attachment_state: HandAttachmentState = _controller.get_attachment_state()
	if attachment_state.is_attached(HandSideScript.Value.LEFT):
		hold_paths.append(attachment_state.get_hold_path(HandSideScript.Value.LEFT))

	if attachment_state.is_attached(HandSideScript.Value.RIGHT):
		hold_paths.append(attachment_state.get_hold_path(HandSideScript.Value.RIGHT))

	return hold_paths

func _on_generated_chunk_spawned(chunk_node: Node2D) -> void:
	Validation.require_condition(chunk_node != null, "RunScene generated chunk hookup requires a chunk node.")
	_connect_generated_pickups(chunk_node)
	_connect_generated_hazards(chunk_node)

func _connect_generated_pickups(chunk_node: Node2D) -> void:
	var pickup_root: Node = chunk_node.get_node("Pickups")
	for pickup_child in pickup_root.get_children():
		Validation.require_condition(pickup_child is GeneratedCoinPickupSpawnAdapterScript, "RunScene generated pickups must use GeneratedCoinPickupSpawnAdapter.")
		var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = pickup_child as GeneratedCoinPickupSpawnAdapterScript
		var _connect_result: int = pickup_spawn.collected.connect(_on_generated_coin_pickup_collected)

func _connect_generated_hazards(chunk_node: Node2D) -> void:
	var hazard_root: Node = chunk_node.get_node("Hazards")
	for hazard_child in hazard_root.get_children():
		Validation.require_condition(hazard_child is GeneratedHazardSpawnAdapterScript, "RunScene generated hazards must use GeneratedHazardSpawnAdapter.")
		var hazard_spawn: GeneratedHazardSpawnAdapterScript = hazard_child as GeneratedHazardSpawnAdapterScript
		var _connect_result: int = hazard_spawn.triggered.connect(_on_generated_hazard_triggered.bind(hazard_spawn))

func _on_generated_coin_pickup_collected(socket_id: StringName, coin_amount: int, body: Node) -> void:
	Validation.require_condition(not String(socket_id).is_empty(), "RunScene generated coin pickup requires a socket id.")
	if not _is_run_active_for_generated_spawns():
		return

	var pickup_applied: bool = _normal_coin_pickup_service.resolve(
		socket_id,
		body,
		_player,
		_run_session,
		_wallet,
		_run_pickup_transaction_ledger,
		_wallet_transaction_service,
		coin_amount
	)
	if not pickup_applied:
		return

	_persist_save_state()
	_refresh_ui()

func _on_generated_hazard_triggered(body: Node, hazard_spawn: GeneratedHazardSpawnAdapterScript) -> void:
	Validation.require_condition(hazard_spawn != null, "RunScene generated hazard hookup requires a hazard spawn.")
	Validation.require_condition(not String(hazard_spawn.socket_id).is_empty(), "RunScene generated hazard contact requires a socket id.")
	if body != _player.get_player_body():
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	match hazard_spawn.hazard_kind:
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER:
			_lethal_hazard_contact_service.resolve(_controller, _player, _run_session)
		GeneratedHazardKindScript.Value.WIND_GUST, GeneratedHazardKindScript.Value.DOWNDRAFT, GeneratedHazardKindScript.Value.UPDRAFT:
			_wind_gust_hazard_contact_service.resolve(
				_controller,
				_player,
				_run_session,
				hazard_spawn.get_impulse_vector_pixels()
			)
		_:
			Validation.require_condition(false, "RunScene requires a supported generated hazard kind.")
	_clear_aim_preview()
	_refresh_ui()

func _is_run_active_for_generated_spawns() -> bool:
	var run_state: int = _run_session.get_state()
	return run_state == RunStateScript.Value.CLIMBING or run_state == RunStateScript.Value.FALLING or run_state == RunStateScript.Value.RESCUE_OFFERED

func _reset_playground() -> void:
	_clear_aim_preview()

	if _controller != null:
		_controller.reset()

	_desktop_input.reset()
	_mobile_input.reset()
	_active_touch_positions = PackedVector2Array()
	_post_run_coin_doubler_reward_id = ""
	_run_pickup_transaction_ledger = CoinTransactionLedgerScript.new()
	_run_session = RunSessionScript.new()
	_run_session.start_run()
	if _chaser_pacing_model != null:
		_chaser_pacing_model.reset()
	if _generated_chunk_coordinator != null:
		_generated_chunk_coordinator.reset_chunks()
	_player.reset_physics(_reset_anchor.global_position)
	_camera.global_position = Vector2(
		_reset_anchor.global_position.x,
		_reset_anchor.global_position.y - _get_climb_tuning_float(&"camera_player_lower_screen_offset_pixels")
	)
	if _chaser_kill_zone != null:
		_apply_equipped_chaser_theme()
		_chaser_kill_zone.reset_to_player_position(
			_player.get_body_global_position().y,
			_get_climb_tuning_float(&"pixels_per_meter"),
			_camera.global_position.x,
			get_viewport_rect().size.x
		)

func _apply_equipped_chaser_theme() -> void:
	if _chaser_kill_zone == null or chaser_theme_catalog == null or cosmetic_loadout == null:
		return

	_chaser_kill_zone.apply_theme(chaser_theme_catalog.get_required_theme_by_id(cosmetic_loadout.chaser_theme_id))

func _apply_saved_cosmetic_selection() -> void:
	if _save_snapshot == null:
		return

	Validation.require_condition(cosmetic_loadout != null, "RunScene requires a cosmetic loadout before applying saved selection.")
	cosmetic_loadout.chaser_theme_id = _save_snapshot.chaser_theme_id

func _duplicate_cosmetic_loadout(loadout: Resource) -> CosmeticLoadoutScript:
	Validation.require_condition(loadout != null, "RunScene requires a cosmetic loadout resource.")
	Validation.require_condition(loadout is CosmeticLoadoutScript, "RunScene requires a CosmeticLoadout resource.")
	var duplicated_loadout: Resource = (loadout as CosmeticLoadoutScript).duplicate(true)
	Validation.require_condition(duplicated_loadout is CosmeticLoadoutScript, "RunScene duplicated cosmetic loadout must implement CosmeticLoadout.")
	var typed_duplicated_loadout: CosmeticLoadoutScript = duplicated_loadout as CosmeticLoadoutScript
	typed_duplicated_loadout.assert_valid()
	return typed_duplicated_loadout

func _initialize_save_storage() -> void:
	if _local_storage_adapter == null:
		_local_storage_adapter = JsonFileLocalStorageAdapterScript.new()
	_save_storage = SaveStorageScript.new(_local_storage_adapter)

func _load_or_create_save_state() -> void:
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before loading save state.")
	if _save_snapshot == null:
		if _save_storage.has_snapshot():
			_save_snapshot = _save_storage.load_snapshot()
		else:
			_save_snapshot = SaveSnapshotScript.new(0, SaveSchemaScript.VERSION, cosmetic_loadout.chaser_theme_id, PackedStringArray())

	_hydrate_runtime_save_state_from_snapshot()

func _hydrate_runtime_save_state_from_snapshot() -> void:
	if _save_snapshot == null:
		return

	_save_snapshot.assert_valid()
	_wallet = WalletScript.new(_save_snapshot.wallet_coins)
	_persistent_transaction_ledger = CoinTransactionLedgerScript.new(_save_snapshot.applied_persistent_transaction_ids)

func _persist_save_state() -> void:
	Validation.require_condition(_save_storage != null, "RunScene requires save storage before persisting save state.")
	var chaser_theme_id: StringName = cosmetic_loadout.chaser_theme_id
	if _save_snapshot != null:
		chaser_theme_id = _save_snapshot.chaser_theme_id
	var snapshot: SaveSnapshotScript = SaveSnapshotScript.new(
		_wallet.get_coins(),
		SaveSchemaScript.VERSION,
		chaser_theme_id,
		_persistent_transaction_ledger.get_transaction_ids()
	)
	_save_storage.save_snapshot(snapshot)
	_save_snapshot = snapshot

func _refresh_ui() -> void:
	if _stamina == null or _run_ui_view == null:
		return

	var hud_state: RefCounted = _run_ui_presenter.build_hud_state(_run_session, _stamina, _wallet)
	var run_end_state: RefCounted = _run_ui_presenter.build_run_end_screen_state(_run_session, _wallet, _can_offer_post_run_coin_doubler())
	_run_ui_view.apply_state_snapshots(hud_state, run_end_state)

func _on_run_end_restart_requested() -> void:
	_reset_playground()
	_refresh_ui()

func _on_post_run_coin_doubler_requested() -> void:
	if not _can_offer_post_run_coin_doubler():
		_refresh_ui()
		return

	var rewarded_ad_result: RefCounted = _rewarded_ads_adapter.show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER)
	Validation.require_condition(rewarded_ad_result != null, "RunScene rewarded ads adapter must return a rewarded ad result.")
	Validation.require_condition(rewarded_ad_result is RewardedAdResultScript, "RunScene rewarded ads adapter must return a RewardedAdResult implementation.")
	var reward_applied: bool = apply_post_run_coin_doubler_reward(rewarded_ad_result, _get_or_create_post_run_coin_doubler_reward_id())
	if not reward_applied:
		_refresh_ui()

func _on_chaser_contacted(body: Node) -> void:
	Validation.require_condition(body != null, "RunScene chaser contact requires a body.")
	if body != _player.get_player_body():
		return

	var run_state: int = _run_session.get_state()
	if run_state == RunStateScript.Value.READY or run_state == RunStateScript.Value.ENDED:
		return

	_chaser_contact_service.resolve(_controller, _player, _run_session)
	_clear_aim_preview()
	_refresh_ui()

func _can_offer_post_run_coin_doubler() -> bool:
	Validation.require_condition(_rewarded_ads_adapter != null, "RunScene requires a rewarded ads adapter before checking post-run doubler availability.")
	if _run_session.get_state() != RunStateScript.Value.ENDED:
		return false

	if _run_session.get_run_earned_coins() <= 0:
		return false

	if not _rewarded_ads_adapter.can_show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER):
		return false

	var reward_id: String = _get_or_create_post_run_coin_doubler_reward_id()
	var transaction_id: String = _post_run_coin_doubler_grant_service.build_transaction_id(reward_id)
	return not _persistent_transaction_ledger.has_transaction_id(transaction_id)

func _get_or_create_post_run_coin_doubler_reward_id() -> String:
	Validation.require_condition(_run_session.get_state() == RunStateScript.Value.ENDED, "RunScene can only build a post-run coin doubler reward id after the run has ended.")
	if _post_run_coin_doubler_reward_id.is_empty():
		_post_run_coin_doubler_reward_id = "run_summary_%s" % str(_run_session.get_instance_id())
	return _post_run_coin_doubler_reward_id

func _bind_post_run_coin_doubler_reward_id(reward_id: String) -> String:
	Validation.require_condition(not reward_id.is_empty(), "RunScene post-run coin doubler reward id cannot be empty.")
	if _post_run_coin_doubler_reward_id.is_empty():
		_post_run_coin_doubler_reward_id = reward_id
	Validation.require_condition(
		_post_run_coin_doubler_reward_id == reward_id,
		"RunScene post-run coin doubler reward id must remain stable for the current run summary."
	)
	return _post_run_coin_doubler_reward_id

func _get_climb_tuning_float(property_name: StringName) -> float:
	var property_value: Variant = climb_tuning.get(property_name)
	if property_value is float:
		return property_value

	if property_value is int:
		var int_value: int = property_value
		return float(int_value)

	Validation.require_condition(false, "Climb tuning property %s must be numeric." % String(property_name))
	return 0.0

func _clear_aim_preview() -> void:
	if _left_aim_preview != null:
		_left_aim_preview.queue_free()
		_left_aim_preview = null

	if _right_aim_preview != null:
		_right_aim_preview.queue_free()
		_right_aim_preview = null

	if _aim_target_marker != null:
		_aim_target_marker.queue_free()
		_aim_target_marker = null

func _update_touch_position(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var _append_result: bool = _active_touch_positions.append(event.position)
		return

	var updated_positions: PackedVector2Array = PackedVector2Array()
	for touch_position in _active_touch_positions:
		if not touch_position.is_equal_approx(event.position):
			var _append_result: bool = updated_positions.append(touch_position)

	_active_touch_positions = updated_positions
