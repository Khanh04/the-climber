extends GutTest

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const GeneratedCoinPickupSpawnAdapterScript = preload("res://src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")
const InMemoryLocalStorageAdapterScript = preload("res://src/platform/storage/in_memory_local_storage_adapter.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const RewardedAdsAdapterScript = preload("res://src/platform/ads/rewarded_ads_adapter.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSceneScript = preload("res://scenes/main/run_scene.gd")
const SaveSchemaScript = preload("res://src/platform/storage/save_schema.gd")
const SaveSnapshotScript = preload("res://src/platform/storage/save_snapshot.gd")
const SaveStorageScript = preload("res://src/platform/storage/save_storage.gd")
const StaminaFallServiceScript = preload("res://src/gameplay/run/stamina_fall_service.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const TransactionSourceScript = preload("res://src/economy/transaction_source.gd")
const UtcDateScript = preload("res://src/platform/clock/utc_date.gd")
const UtcDateProviderScript = preload("res://src/platform/clock/utc_date_provider.gd")

class StubUtcDateProvider extends UtcDateProviderScript:
    var _utc_date: UtcDateScript

    func _init(year: int, month: int, day: int) -> void:
        _utc_date = UtcDateScript.new(year, month, day)

    func get_current_utc_date() -> UtcDateScript:
        return _utc_date

class StubRewardedAdsAdapter extends RewardedAdsAdapterScript:
    var _can_show_continue: bool = false
    var _continue_rewarded_ad_result: RewardedAdResultScript = null
    var _can_show_post_run_coin_doubler: bool = false
    var _post_run_coin_doubler_rewarded_ad_result: RewardedAdResultScript = null
    var show_call_count: int = 0
    var last_shown_placement: int = -1

    func _init(
        can_show_continue: bool = false,
        continue_rewarded_ad_result: RewardedAdResultScript = null,
        can_show_post_run_coin_doubler: bool = false,
        post_run_coin_doubler_rewarded_ad_result: RewardedAdResultScript = null
    ) -> void:
        _can_show_continue = can_show_continue
        _continue_rewarded_ad_result = continue_rewarded_ad_result
        _can_show_post_run_coin_doubler = can_show_post_run_coin_doubler
        _post_run_coin_doubler_rewarded_ad_result = post_run_coin_doubler_rewarded_ad_result

    func can_show(placement_value: int) -> bool:
        RewardedAdPlacementScript.assert_valid(placement_value)
        match placement_value:
            RewardedAdPlacementScript.Value.CONTINUE:
                return _can_show_continue
            RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER:
                return _can_show_post_run_coin_doubler
            RewardedAdPlacementScript.Value.PRE_RUN_VENDING_MACHINE:
                return false
            _:
                Validation.require_condition(false, "StubRewardedAdsAdapter requires a supported placement.")
                return false

    func show(placement_value: int) -> RefCounted:
        RewardedAdPlacementScript.assert_valid(placement_value)
        Validation.require_condition(can_show(placement_value), "StubRewardedAdsAdapter cannot show the requested placement.")
        show_call_count += 1
        last_shown_placement = placement_value
        match placement_value:
            RewardedAdPlacementScript.Value.CONTINUE:
                Validation.require_condition(_continue_rewarded_ad_result != null, "StubRewardedAdsAdapter requires a continue result when continue ads are enabled.")
                return _continue_rewarded_ad_result
            RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER:
                Validation.require_condition(
                    _post_run_coin_doubler_rewarded_ad_result != null,
                    "StubRewardedAdsAdapter requires a post-run doubler result when that placement is enabled."
                )
                return _post_run_coin_doubler_rewarded_ad_result
            RewardedAdPlacementScript.Value.PRE_RUN_VENDING_MACHINE:
                Validation.require_condition(false, "StubRewardedAdsAdapter does not support pre-run vending machine tests.")
                return RewardedAdResultScript.new(placement_value, RewardedAdOutcomeScript.Value.UNAVAILABLE, false)
            _:
                Validation.require_condition(false, "StubRewardedAdsAdapter requires a supported placement.")
                return RewardedAdResultScript.new(placement_value, RewardedAdOutcomeScript.Value.UNAVAILABLE, false)

func test_run_scene_wires_required_nodes_and_starts_run() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_not_null(playground.get_node_or_null("PlayerCharacter"))
    assert_not_null(playground.get_node_or_null("ChaserKillZone"))
    assert_not_null(playground.get_player_body_for_test())
    assert_not_null(playground.get_left_hand_anchor_for_test())
    assert_not_null(playground.get_right_hand_anchor_for_test())
    assert_not_null(playground.get_node_or_null("ResetAnchor"))
    assert_not_null(playground.get_node_or_null("DevCamera"))
    assert_not_null(playground.get_node_or_null("UiLayer/RunHud"))
    assert_not_null(playground.get_node_or_null("UiLayer/RunEndScreen"))
    assert_not_null(playground.get_node_or_null("GeneratedChunks"))
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

func test_run_scene_uses_extended_starting_stamina_for_playtesting() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_eq(playground.stamina_tuning.one_hand_seconds, 20.0)

func test_run_scene_applies_equipped_chaser_theme_from_cosmetic_loadout() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var cosmetic_loadout := CosmeticLoadoutScript.new()

    assert_not_null(playground)
    cosmetic_loadout.chaser_theme_id = &"glitch"
    playground.cosmetic_loadout = cosmetic_loadout
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"glitch")

    playground.reset_for_test()
    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"glitch")

func test_run_scene_save_snapshot_overrides_default_chaser_theme_selection() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var save_snapshot: SaveSnapshotScript = SaveSnapshotScript.new(12, SaveSchemaScript.VERSION, &"hot_coffee")

    assert_not_null(playground)
    playground.set_save_snapshot(save_snapshot)
    add_child_autofree(playground)
    await get_tree().process_frame

    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"hot_coffee")
    assert_eq(playground.get_wallet_for_test().get_coins(), 12)

    playground.reset_for_test()
    assert_eq(playground.get_chaser_for_test().chaser_theme.theme_id, &"hot_coffee")

func test_run_scene_handholds_have_required_group() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var handholds: Array = playground.get_tree().get_nodes_in_group(&"handhold")

    assert_gt(handholds.size(), 0)
    for handhold in handholds:
        assert_true(handhold is StaticBody2D)

func test_run_scene_generated_opener_holds_are_in_initial_grip_range() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var left_anchor: Marker2D = playground.get_left_hand_anchor_for_test()
    var right_anchor: Marker2D = playground.get_right_hand_anchor_for_test()
    var starter_holds: Array[StaticBody2D] = _get_generated_opener_hold_pair(playground)
    var left_hold: StaticBody2D = starter_holds[0]
    var right_hold: StaticBody2D = starter_holds[1]

    assert_not_null(left_anchor)
    assert_not_null(right_anchor)
    assert_not_null(left_hold)
    assert_not_null(right_hold)
    assert_lte(left_anchor.global_position.distance_to(left_hold.global_position), playground.climb_tuning.handhold_detection_radius_pixels)
    assert_lte(right_anchor.global_position.distance_to(right_hold.global_position), playground.climb_tuning.handhold_detection_radius_pixels)

func test_run_scene_climb_holds_do_not_block_player_body() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var starter_holds: Array[StaticBody2D] = _get_generated_opener_hold_pair(playground)
    var left_hold: StaticBody2D = starter_holds[0]
    var right_hold: StaticBody2D = starter_holds[1]
    var safe_platform: StaticBody2D = playground.get_node("Handholds/HoldSafePlatform") as StaticBody2D

    assert_not_null(player_body)
    assert_not_null(left_hold)
    assert_not_null(right_hold)
    assert_not_null(safe_platform)
    assert_false((player_body.collision_mask & left_hold.collision_layer) != 0)
    assert_false((player_body.collision_mask & right_hold.collision_layer) != 0)
    assert_true((player_body.collision_mask & safe_platform.collision_layer) != 0)

func test_run_scene_has_tall_non_blocking_test_route() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var non_blocking_hold_count: int = 0
    var highest_hold_y: float = INF
    var lowest_hold_y: float = -INF

    assert_not_null(player_body)
    for handhold in playground.get_tree().get_nodes_in_group(&"handhold"):
        assert_true(handhold is StaticBody2D)
        var handhold_body: StaticBody2D = handhold
        if (player_body.collision_mask & handhold_body.collision_layer) == 0:
            non_blocking_hold_count += 1
            highest_hold_y = minf(highest_hold_y, handhold_body.global_position.y)
            lowest_hold_y = maxf(lowest_hold_y, handhold_body.global_position.y)

    assert_gte(non_blocking_hold_count, 18)
    assert_gt(lowest_hold_y - highest_hold_y, 1200.0)

func test_run_scene_starts_generated_chunks_from_reset_anchor_without_authored_starter_route_nodes() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D
    var generated_chunks_root: Node2D = playground.get_node("GeneratedChunks") as Node2D
    var first_generated_chunk: Node2D = playground.get_generated_chunk_coordinator_for_test().get_chunk_node(0)
    var removed_start_hold: Node = playground.get_node_or_null("Handholds/HoldStartLeft")

    assert_not_null(reset_anchor)
    assert_not_null(generated_chunks_root)
    assert_not_null(first_generated_chunk)
    assert_null(removed_start_hold)
    assert_eq(generated_chunks_root.get_child_count(), playground.generation_tuning.chunk_spawn_ahead_count)
    assert_eq(first_generated_chunk.global_position, reset_anchor.global_position)

    for generated_chunk in generated_chunks_root.get_children():
        assert_true(generated_chunk is Node2D)
        var generated_chunk_root: Node2D = generated_chunk as Node2D
        var generated_handhold_root: Node = generated_chunk_root.get_node("Handholds")
        var pickup_root: Node = generated_chunk_root.get_node("Pickups")
        var hazard_root: Node = generated_chunk_root.get_node("Hazards")

        assert_not_null(generated_handhold_root)
        assert_not_null(pickup_root)
        assert_not_null(hazard_root)
        assert_gte(generated_handhold_root.get_child_count(), 1)

func test_run_scene_generated_seed_key_tracks_injected_utc_rollover() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var first_playground_node: Node = scene.instantiate()
    var first_playground: RunSceneScript = first_playground_node as RunSceneScript
    var second_playground_node: Node = scene.instantiate()
    var second_playground: RunSceneScript = second_playground_node as RunSceneScript

    assert_not_null(first_playground)
    assert_not_null(second_playground)
    first_playground.set_utc_date_provider(StubUtcDateProvider.new(2026, 5, 14))
    second_playground.set_utc_date_provider(StubUtcDateProvider.new(2026, 5, 15))
    add_child_autofree(first_playground)
    add_child_autofree(second_playground)
    await get_tree().process_frame

    var first_generated_chunk: Node2D = first_playground.get_generated_chunk_coordinator_for_test().get_chunk_node(0)
    var second_generated_chunk: Node2D = second_playground.get_generated_chunk_coordinator_for_test().get_chunk_node(0)
    var first_seed_key: String = _get_required_string_meta(first_generated_chunk, &"seed_key")
    var second_seed_key: String = _get_required_string_meta(second_generated_chunk, &"seed_key")
    var first_generator_version: String = _get_required_string_meta(first_generated_chunk, &"generator_version")
    var second_generator_version: String = _get_required_string_meta(second_generated_chunk, &"generator_version")

    assert_eq(first_seed_key, "generator_v1:2026-05-14")
    assert_eq(second_seed_key, "generator_v1:2026-05-15")
    assert_ne(first_seed_key, second_seed_key)
    assert_eq(first_generator_version, first_playground.generation_tuning.generator_version)
    assert_eq(second_generator_version, second_playground.generation_tuning.generator_version)

func test_run_scene_generated_coin_pickups_increment_run_coins() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)

    assert_not_null(playground)
    playground.set_local_storage_adapter(local_storage)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var pickup_nodes: Array = playground.get_tree().get_nodes_in_group(GeneratedCoinPickupSpawnAdapterScript.GROUP_NAME)

    assert_not_null(player_body)
    assert_gt(pickup_nodes.size(), 0)

    var raw_pickup_node: Variant = pickup_nodes[0]
    assert_true(raw_pickup_node is GeneratedCoinPickupSpawnAdapterScript)
    var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = raw_pickup_node
    var wallet_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/WalletMetric/WalletValueLabel") as Label
    assert_not_null(pickup_spawn)
    assert_not_null(wallet_value_label)
    assert_eq(playground.get_run_session_for_test().get_run_earned_coins(), 0)
    assert_eq(playground.get_wallet_for_test().get_coins(), 0)
    assert_eq(wallet_value_label.text, "0")

    pickup_spawn.collected.emit(pickup_spawn.socket_id, pickup_spawn.coin_amount, player_body)

    assert_eq(playground.get_run_session_for_test().get_run_earned_coins(), pickup_spawn.coin_amount)
    assert_eq(playground.get_wallet_for_test().get_coins(), pickup_spawn.coin_amount)
    assert_eq(wallet_value_label.text, str(pickup_spawn.coin_amount))
    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, pickup_spawn.coin_amount)

func test_run_scene_duplicate_generated_coin_pickups_do_not_double_bank_wallet_or_run_coins() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)

    assert_not_null(playground)
    playground.set_local_storage_adapter(local_storage)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var pickup_nodes: Array = playground.get_tree().get_nodes_in_group(GeneratedCoinPickupSpawnAdapterScript.GROUP_NAME)

    assert_not_null(player_body)
    assert_gt(pickup_nodes.size(), 0)

    var raw_pickup_node: Variant = pickup_nodes[0]
    assert_true(raw_pickup_node is GeneratedCoinPickupSpawnAdapterScript)
    var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = raw_pickup_node

    pickup_spawn.collected.emit(pickup_spawn.socket_id, pickup_spawn.coin_amount, player_body)
    pickup_spawn.collected.emit(pickup_spawn.socket_id, pickup_spawn.coin_amount, player_body)

    assert_eq(playground.get_run_session_for_test().get_run_earned_coins(), pickup_spawn.coin_amount)
    assert_eq(playground.get_wallet_for_test().get_coins(), pickup_spawn.coin_amount)
    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, pickup_spawn.coin_amount)

func test_run_scene_persistent_transactions_bank_once_across_reloaded_save_state() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
    var first_playground_node: Node = scene.instantiate()
    var first_playground: RunSceneScript = first_playground_node as RunSceneScript

    assert_not_null(first_playground)
    first_playground.set_local_storage_adapter(local_storage)
    add_child_autofree(first_playground)
    await get_tree().process_frame

    assert_true(first_playground.apply_persistent_coin_transaction("ad_reward:continue_offer_01", TransactionSourceScript.Value.AD_REWARD, 9))
    assert_eq(first_playground.get_wallet_for_test().get_coins(), 9)
    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, 9)
    assert_eq(save_storage.load_snapshot().applied_persistent_transaction_ids, PackedStringArray(["ad_reward:continue_offer_01"]))

    var second_playground_node: Node = scene.instantiate()
    var second_playground: RunSceneScript = second_playground_node as RunSceneScript

    assert_not_null(second_playground)
    second_playground.set_local_storage_adapter(local_storage)
    add_child_autofree(second_playground)
    await get_tree().process_frame

    assert_eq(second_playground.get_wallet_for_test().get_coins(), 9)
    assert_false(second_playground.apply_persistent_coin_transaction("ad_reward:continue_offer_01", TransactionSourceScript.Value.AD_REWARD, 9))
    assert_eq(second_playground.get_wallet_for_test().get_coins(), 9)
    assert_eq(save_storage.load_snapshot().wallet_coins, 9)

func test_run_scene_post_run_coin_doubler_banks_run_coins_once_after_run_end() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    playground.set_local_storage_adapter(local_storage)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var pickup_nodes: Array = playground.get_tree().get_nodes_in_group(GeneratedCoinPickupSpawnAdapterScript.GROUP_NAME)

    assert_not_null(player_body)
    assert_gt(pickup_nodes.size(), 0)

    var raw_pickup_node: Variant = pickup_nodes[0]
    assert_true(raw_pickup_node is GeneratedCoinPickupSpawnAdapterScript)
    var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = raw_pickup_node
    var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER,
        RewardedAdOutcomeScript.Value.COMPLETED,
        true
    )

    pickup_spawn.collected.emit(pickup_spawn.socket_id, pickup_spawn.coin_amount, player_body)
    playground.get_run_session_for_test().end_run(RunEndReasonScript.Value.CHASER_CONTACT)

    assert_true(playground.apply_post_run_coin_doubler_reward(rewarded_ad_result, "summary_01"))
    assert_eq(playground.get_wallet_for_test().get_coins(), pickup_spawn.coin_amount * 2)
    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, pickup_spawn.coin_amount * 2)
    assert_eq(
        save_storage.load_snapshot().applied_persistent_transaction_ids,
        PackedStringArray(["ad_reward:post_run_coin_doubler:summary_01"])
    )
    assert_false(playground.apply_post_run_coin_doubler_reward(rewarded_ad_result, "summary_01"))
    assert_eq(playground.get_wallet_for_test().get_coins(), pickup_spawn.coin_amount * 2)

func test_run_scene_run_end_screen_requests_post_run_coin_doubler_through_rewarded_ads_adapter() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var local_storage: InMemoryLocalStorageAdapterScript = InMemoryLocalStorageAdapterScript.new()
    var save_storage: SaveStorageScript = SaveStorageScript.new(local_storage)
    var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER,
        RewardedAdOutcomeScript.Value.COMPLETED,
        true
    )
    var rewarded_ads_adapter: StubRewardedAdsAdapter = StubRewardedAdsAdapter.new(false, null, true, rewarded_ad_result)
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    playground.set_local_storage_adapter(local_storage)
    playground.set_rewarded_ads_adapter(rewarded_ads_adapter)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var pickup_nodes: Array = playground.get_tree().get_nodes_in_group(GeneratedCoinPickupSpawnAdapterScript.GROUP_NAME)

    assert_not_null(player_body)
    assert_gt(pickup_nodes.size(), 0)

    var raw_pickup_node: Variant = pickup_nodes[0]
    assert_true(raw_pickup_node is GeneratedCoinPickupSpawnAdapterScript)
    var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = raw_pickup_node
    var post_run_coin_doubler_button: Button = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/PostRunCoinDoublerButton"
    ) as Button

    assert_not_null(post_run_coin_doubler_button)

    pickup_spawn.collected.emit(pickup_spawn.socket_id, pickup_spawn.coin_amount, player_body)
    playground.resolve_chaser_contact_for_test()

    assert_true(post_run_coin_doubler_button.visible)

    var _emit_result: int = post_run_coin_doubler_button.emit_signal("pressed")

    assert_eq(rewarded_ads_adapter.show_call_count, 1)
    assert_eq(rewarded_ads_adapter.last_shown_placement, RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER)
    assert_eq(playground.get_wallet_for_test().get_coins(), pickup_spawn.coin_amount * 2)
    assert_true(save_storage.has_snapshot())
    assert_eq(save_storage.load_snapshot().wallet_coins, pickup_spawn.coin_amount * 2)
    assert_false(post_run_coin_doubler_button.visible)

func test_run_scene_run_end_screen_requests_rewarded_continue_through_rewarded_ads_adapter() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.CONTINUE,
        RewardedAdOutcomeScript.Value.COMPLETED,
        true
    )
    var rewarded_ads_adapter: StubRewardedAdsAdapter = StubRewardedAdsAdapter.new(true, rewarded_ad_result)
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    playground.set_rewarded_ads_adapter(rewarded_ads_adapter)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D
    var rewarded_continue_button: Button = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton"
    ) as Button
    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control

    assert_not_null(player_body)
    assert_not_null(camera)
    assert_not_null(rewarded_continue_button)
    assert_not_null(run_end_screen)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    assert_true(run_end_screen.visible)
    assert_true(rewarded_continue_button.visible)

    var _emit_result: int = rewarded_continue_button.emit_signal("pressed")

    assert_eq(rewarded_ads_adapter.show_call_count, 1)
    assert_eq(rewarded_ads_adapter.last_shown_placement, RewardedAdPlacementScript.Value.CONTINUE)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_true(playground.get_run_session_for_test().has_used_rescue())
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.controlled_climb())
    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 2)
    assert_false(run_end_screen.visible)

    playground._physics_process(0.0)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

func test_run_scene_rewarded_continue_stays_available_after_cancelled_ad_attempt() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.CONTINUE,
        RewardedAdOutcomeScript.Value.CANCELLED,
        false
    )
    var rewarded_ads_adapter: StubRewardedAdsAdapter = StubRewardedAdsAdapter.new(true, rewarded_ad_result)
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    playground.set_rewarded_ads_adapter(rewarded_ads_adapter)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D
    var rewarded_continue_button: Button = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton"
    ) as Button

    assert_not_null(player_body)
    assert_not_null(camera)
    assert_not_null(rewarded_continue_button)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    assert_true(rewarded_continue_button.visible)

    var _emit_result: int = rewarded_continue_button.emit_signal("pressed")

    assert_eq(rewarded_ads_adapter.show_call_count, 1)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_false(playground.get_run_session_for_test().has_used_rescue())
    assert_true(rewarded_continue_button.visible)
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())

    var ad_feedback_label: Label = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/AdFeedbackLabel"
    ) as Label
    assert_not_null(ad_feedback_label)
    assert_true(ad_feedback_label.visible)
    assert_string_contains(ad_feedback_label.text, "cancelled")

func test_run_scene_shows_failed_feedback_after_failed_ad_attempt() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.CONTINUE,
        RewardedAdOutcomeScript.Value.FAILED,
        false
    )
    var rewarded_ads_adapter: StubRewardedAdsAdapter = StubRewardedAdsAdapter.new(true, rewarded_ad_result)
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    playground.set_rewarded_ads_adapter(rewarded_ads_adapter)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D
    var rewarded_continue_button: Button = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton"
    ) as Button

    assert_not_null(player_body)
    assert_not_null(camera)
    assert_not_null(rewarded_continue_button)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    assert_true(rewarded_continue_button.visible)

    var _emit_result: int = rewarded_continue_button.emit_signal("pressed")

    assert_eq(rewarded_ads_adapter.show_call_count, 1)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_false(playground.get_run_session_for_test().has_used_rescue())
    assert_true(rewarded_continue_button.visible)

    var ad_feedback_label: Label = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/AdFeedbackLabel"
    ) as Label
    assert_not_null(ad_feedback_label)
    assert_true(ad_feedback_label.visible)
    assert_string_contains(ad_feedback_label.text, "failed")

func test_run_scene_hides_rewarded_continue_when_ads_are_unavailable() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D
    var rewarded_continue_button: Button = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton"
    ) as Button
    var summary_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/SummaryLabel") as Label

    assert_not_null(player_body)
    assert_not_null(camera)
    assert_not_null(rewarded_continue_button)
    assert_not_null(summary_label)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_false(rewarded_continue_button.visible)
    assert_string_contains(summary_label.text, "Rewarded continue is unavailable")

func test_run_scene_second_eligible_fall_after_rewarded_continue_does_not_offer_another_continue() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var rewarded_ad_result: RewardedAdResultScript = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.CONTINUE,
        RewardedAdOutcomeScript.Value.COMPLETED,
        true
    )
    var rewarded_ads_adapter: StubRewardedAdsAdapter = StubRewardedAdsAdapter.new(true, rewarded_ad_result)
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    playground.set_rewarded_ads_adapter(rewarded_ads_adapter)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D
    var rewarded_continue_button: Button = playground.get_node(
        "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RewardedContinueButton"
    ) as Button
    var title_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label

    assert_not_null(player_body)
    assert_not_null(camera)
    assert_not_null(rewarded_continue_button)
    assert_not_null(title_label)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    var _emit_result: int = rewarded_continue_button.emit_signal("pressed")

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 48.0
    )
    playground._physics_process(0.0)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.ENDED)
    assert_true(playground.get_run_session_for_test().has_used_rescue())
    assert_false(rewarded_continue_button.visible)
    assert_eq(title_label.text, "Run Ended")

func test_run_scene_generated_spike_cluster_hazards_end_run() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var hazard_spawn: GeneratedHazardSpawnAdapterScript = _wire_generated_hazard_for_test(
        playground,
        GeneratedHazardKindScript.Value.SPIKE_CLUSTER,
        Vector2.ZERO,
        &"test_spike_hazard"
    )

    assert_not_null(player_body)
    assert_not_null(hazard_spawn)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

    hazard_spawn.triggered.emit(player_body)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.ENDED)
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.LETHAL_HAZARD)
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())

func test_run_scene_generated_wind_gust_hazards_begin_nonterminal_fall() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var impulse_vector_pixels: Vector2 = Vector2(-240.0, -160.0)
    var hazard_spawn: GeneratedHazardSpawnAdapterScript = _wire_generated_hazard_for_test(
        playground,
        GeneratedHazardKindScript.Value.WIND_GUST,
        impulse_vector_pixels,
        &"test_wind_hazard"
    )

    assert_not_null(player_body)
    assert_not_null(hazard_spawn)
    player_body.linear_velocity = Vector2.ZERO
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_false(playground.get_run_session_for_test().has_end_reason())

    hazard_spawn.triggered.emit(player_body)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.FALLING)
    assert_false(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_true(player_body.linear_velocity.is_equal_approx(impulse_vector_pixels))

func test_run_scene_generated_downdraft_hazards_begin_nonterminal_fall() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var impulse_vector_pixels: Vector2 = Vector2(90.0, 260.0)
    var hazard_spawn: GeneratedHazardSpawnAdapterScript = _wire_generated_hazard_for_test(
        playground,
        GeneratedHazardKindScript.Value.DOWNDRAFT,
        impulse_vector_pixels,
        &"test_downdraft_hazard"
    )

    assert_not_null(player_body)
    assert_not_null(hazard_spawn)
    player_body.linear_velocity = Vector2.ZERO
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_false(playground.get_run_session_for_test().has_end_reason())

    hazard_spawn.triggered.emit(player_body)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.FALLING)
    assert_false(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_true(player_body.linear_velocity.is_equal_approx(impulse_vector_pixels))

func test_run_scene_generated_updraft_hazards_begin_nonterminal_fall() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var impulse_vector_pixels: Vector2 = Vector2(-110.0, -320.0)
    var hazard_spawn: GeneratedHazardSpawnAdapterScript = _wire_generated_hazard_for_test(
        playground,
        GeneratedHazardKindScript.Value.UPDRAFT,
        impulse_vector_pixels,
        &"test_updraft_hazard"
    )

    assert_not_null(player_body)
    assert_not_null(hazard_spawn)
    player_body.linear_velocity = Vector2.ZERO
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_false(playground.get_run_session_for_test().has_end_reason())

    hazard_spawn.triggered.emit(player_body)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.FALLING)
    assert_false(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_true(player_body.linear_velocity.is_equal_approx(impulse_vector_pixels))

func test_run_scene_camera_follows_player_upward() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var starting_camera_y: float = camera.global_position.y
    player_body.global_position = Vector2(player_body.global_position.x, player_body.global_position.y - 500.0)
    playground._physics_process(0.0)

    assert_lt(camera.global_position.y, starting_camera_y)
    assert_eq(camera.global_position.y, player_body.global_position.y - playground.get_camera_player_lower_screen_offset_for_test())

func _wire_generated_hazard_for_test(
    playground: RunSceneScript,
    hazard_kind: int,
    impulse_vector_pixels: Vector2,
    socket_id: StringName
) -> GeneratedHazardSpawnAdapterScript:
    var chunk_node: Node2D = Node2D.new()
    chunk_node.name = &"GeneratedChunkHarness"

    var pickup_root: Node = Node.new()
    pickup_root.name = &"Pickups"
    chunk_node.add_child(pickup_root)

    var hazard_root: Node = Node.new()
    hazard_root.name = &"Hazards"
    chunk_node.add_child(hazard_root)

    var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
    hazard_spawn.name = socket_id
    hazard_spawn.configure_hazard(socket_id, hazard_kind, Vector2.ZERO, impulse_vector_pixels)
    hazard_root.add_child(hazard_spawn)

    playground.add_child(chunk_node)
    playground._on_generated_chunk_spawned(chunk_node)

    return hazard_spawn

func test_run_scene_bottom_screen_fall_routes_through_run_session() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    _attach_to_generated_opener_holds(playground)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.BOTTOM_SCREEN_FALL)
    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())

func test_run_scene_hud_displays_initial_run_snapshot() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var height_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/HeightMetric/HeightValueLabel") as Label
    var stamina_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/StaminaMetric/StaminaValueLabel") as Label
    var wallet_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/WalletMetric/WalletValueLabel") as Label
    var coins_value_label: Label = playground.get_node("UiLayer/RunHud/Panel/ContentMargin/Metrics/CoinsMetric/CoinsValueLabel") as Label
    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control

    assert_not_null(height_value_label)
    assert_not_null(stamina_value_label)
    assert_not_null(wallet_value_label)
    assert_not_null(coins_value_label)
    assert_not_null(run_end_screen)
    assert_eq(height_value_label.text, "0.0 m")
    assert_eq(stamina_value_label.text, "20.0 / 20.0")
    assert_eq(wallet_value_label.text, "0")
    assert_eq(coins_value_label.text, "0")
    assert_false(run_end_screen.visible)

func test_run_scene_bottom_screen_fall_shows_run_end_screen() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control
    var title_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label
    var summary_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/SummaryLabel") as Label

    assert_not_null(run_end_screen)
    assert_not_null(title_label)
    assert_not_null(summary_label)
    assert_true(run_end_screen.visible)
    assert_eq(title_label.text, "Rescue Offered")
    assert_true(summary_label.text.contains("Wallet Coins: 0"))

func test_run_scene_chaser_contact_ends_run_without_rescue_and_restart_resets_chaser() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var chaser: ChaserKillZoneScript = playground.get_chaser_for_test()
    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D
    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control
    var title_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/TitleLabel") as Label
    var reason_label: Label = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/ReasonLabel") as Label
    var restart_button: Button = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button

    assert_not_null(chaser)
    assert_not_null(reset_anchor)
    assert_not_null(run_end_screen)
    assert_not_null(title_label)
    assert_not_null(reason_label)
    assert_not_null(restart_button)

    _attach_to_generated_opener_holds(playground, true, false)

    chaser.global_position.y = 100.0
    playground.resolve_chaser_contact_for_test()

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.ENDED)
    assert_true(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.CHASER_CONTACT)
    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_player_for_test().get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_true(run_end_screen.visible)
    assert_eq(title_label.text, "Run Ended")
    assert_eq(reason_label.text, "Reason: Chaser contact")

    var _emit_result: int = restart_button.emit_signal("pressed")

    var expected_reset_chaser_y: float = reset_anchor.global_position.y + (chaser.chaser_tuning.initial_spawn_offset_meters * playground.climb_tuning.pixels_per_meter) + (chaser.kill_zone_height_pixels * 0.5)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_false(run_end_screen.visible)
    assert_eq(chaser.global_position.y, expected_reset_chaser_y)

func test_run_scene_exposes_chaser_feedback_hooks_for_playtesting() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var chaser: ChaserKillZoneScript = playground.get_chaser_for_test()
    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var pixels_per_meter: float = playground.climb_tuning.pixels_per_meter

    assert_not_null(chaser)
    assert_not_null(player_body)

    chaser.global_position.y = player_body.global_position.y + (chaser.kill_zone_height_pixels * 0.5) + (chaser.chaser_tuning.far_distance_for_min_intensity_meters * pixels_per_meter)
    playground._physics_process(0.0)
    var far_intensity: float = playground.get_chaser_feedback_intensity_ratio_for_test()

    chaser.global_position.y = player_body.global_position.y + (chaser.kill_zone_height_pixels * 0.5) + (chaser.chaser_tuning.near_distance_for_max_intensity_meters * pixels_per_meter)
    playground._physics_process(0.0)
    var near_intensity: float = playground.get_chaser_feedback_intensity_ratio_for_test()
    var feedback_snapshot: ChaserFeedbackSnapshotScript = playground.get_chaser_feedback_snapshot_for_test()

    assert_lt(far_intensity, near_intensity)
    assert_eq(feedback_snapshot.pace_state, ChaserPacingModelScript.PaceState.CAMPING)
    assert_gte(feedback_snapshot.speed_intensity_ratio, 0.0)
    assert_lte(feedback_snapshot.speed_intensity_ratio, 1.0)

func test_run_scene_camera_follows_player_downward_after_fall_resolution() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D

    assert_not_null(player_body)
    assert_not_null(camera)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    var camera_after_fall_resolution: float = camera.global_position.y
    player_body.global_position = Vector2(player_body.global_position.x, player_body.global_position.y + 220.0)
    playground._physics_process(0.0)

    assert_gt(camera.global_position.y, camera_after_fall_resolution)
    assert_eq(camera.global_position.y, player_body.global_position.y - playground.get_camera_player_lower_screen_offset_for_test())

func test_run_scene_run_end_restart_button_resets_run() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var camera: Camera2D = playground.get_node("DevCamera") as Camera2D
    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D

    assert_not_null(player_body)
    assert_not_null(camera)
    assert_not_null(reset_anchor)

    var viewport_size: Vector2 = playground.get_viewport_rect().size
    player_body.global_position = Vector2(
        player_body.global_position.x,
        camera.global_position.y + (viewport_size.y * 0.5) + playground.get_bottom_fall_margin_for_test() + 24.0
    )
    playground._physics_process(0.0)

    var restart_button: Button = playground.get_node("UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/RestartButton") as Button
    var run_end_screen: Control = playground.get_node("UiLayer/RunEndScreen") as Control

    assert_not_null(restart_button)
    assert_not_null(run_end_screen)
    assert_true(run_end_screen.visible)

    var _emit_result: int = restart_button.emit_signal("pressed")

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_eq(player_body.global_position, reset_anchor.global_position)
    assert_eq(player_body.linear_velocity, Vector2.ZERO)
    assert_eq(camera.global_position.y, reset_anchor.global_position.y - playground.get_camera_player_lower_screen_offset_for_test())
    assert_false(run_end_screen.visible)

func test_run_scene_has_safe_start_block_below_spawn() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D
    var safe_platform: StaticBody2D = playground.get_node("Handholds/HoldSafePlatform") as StaticBody2D

    assert_not_null(reset_anchor)
    assert_not_null(safe_platform)
    assert_true(safe_platform.is_in_group(&"handhold"))
    assert_gt(safe_platform.global_position.y, reset_anchor.global_position.y)
    assert_lte(safe_platform.global_position.y - reset_anchor.global_position.y, 80.0)

func test_run_scene_left_grip_creates_and_releases_runtime_link() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    _attach_to_generated_opener_holds(playground, true, false)
    playground.sync_grip_links_for_test()

    var left_link: Line2D = playground.get_player_for_test().get_left_runtime_grip_link()
    assert_not_null(left_link)
    assert_eq(left_link.get_point_count(), 2)

    playground.get_controller_for_test().get_attachment_state().release(HandSide.Value.LEFT)
    playground.sync_grip_links_for_test()
    await get_tree().process_frame

    assert_null(playground.get_player_for_test().get_left_runtime_grip_link())

func test_run_scene_aim_preview_shows_for_unattached_hands_when_aiming() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var input_frame: PlayerInputFrameScript = PlayerInputFrameScript.new([], [], AimInputIntentScript.new(Vector2.UP))
    playground.sync_aim_preview_for_test(input_frame)

    var left_preview: Line2D = playground.get_node_or_null("LeftAimPreview") as Line2D
    var right_preview: Line2D = playground.get_node_or_null("RightAimPreview") as Line2D
    var aim_marker: Polygon2D = playground.get_node_or_null("AimTargetMarker") as Polygon2D

    assert_not_null(left_preview)
    assert_not_null(right_preview)
    assert_not_null(aim_marker)
    assert_eq(left_preview.get_point_count(), 2)
    assert_eq(right_preview.get_point_count(), 2)

func test_run_scene_aim_preview_hides_for_attached_hand() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    _attach_to_generated_opener_holds(playground, true, false)

    var input_frame: PlayerInputFrameScript = PlayerInputFrameScript.new([], [], AimInputIntentScript.new(Vector2.RIGHT))
    playground.sync_aim_preview_for_test(input_frame)

    assert_null(playground.get_node_or_null("LeftAimPreview"))
    assert_not_null(playground.get_node_or_null("RightAimPreview"))
    assert_not_null(playground.get_node_or_null("AimTargetMarker"))

func test_run_scene_reset_clears_runtime_attachments_and_restarts_run() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    _attach_to_generated_opener_holds(playground, true, false)
    playground.reset_for_test()

    assert_eq(playground.get_controller_for_test().get_attachment_state().get_attached_hand_count(), 0)
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)

func test_run_scene_debug_reset_action_works_while_falling() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var reset_anchor: Marker2D = playground.get_node("ResetAnchor") as Marker2D

    assert_not_null(player_body)
    assert_not_null(reset_anchor)

    playground.get_run_session_for_test().begin_fall()
    player_body.global_position = Vector2(100.0, 100.0)
    player_body.linear_velocity = Vector2(200.0, 500.0)

    var reset_event := InputEventAction.new()
    reset_event.action = &"debug_reset_run"
    reset_event.pressed = true
    playground._input(reset_event)

    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.CLIMBING)
    assert_eq(player_body.global_position, reset_anchor.global_position)
    assert_eq(player_body.linear_velocity, Vector2.ZERO)

func test_run_scene_stamina_fall_routes_through_service_shape() -> void:
    var scene: PackedScene = load("res://scenes/main/run_scene.tscn")
    var playground_node: Node = scene.instantiate()
    var playground: RunSceneScript = playground_node as RunSceneScript
    var stamina_fall_service: Object = StaminaFallServiceScript.new()

    assert_not_null(playground)
    add_child_autofree(playground)
    await get_tree().process_frame

    var player: PlayerCharacter = playground.get_player_for_test()

    assert_not_null(player)
    stamina_fall_service.call("resolve", player, playground.get_run_session_for_test())

    assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
    assert_eq(playground.get_run_session_for_test().get_state(), RunStateScript.Value.RESCUE_OFFERED)
    assert_true(playground.get_run_session_for_test().has_end_reason())
    assert_eq(playground.get_run_session_for_test().get_end_reason(), RunEndReasonScript.Value.STAMINA_FALL)

func _get_generated_opener_hold_pair(playground: RunSceneScript) -> Array[StaticBody2D]:
    var chunk_node: Node2D = playground.get_generated_chunk_coordinator_for_test().get_chunk_node(0)
    var handhold_root: Node = chunk_node.get_node("Handholds")
    var player_body: RigidBody2D = playground.get_player_body_for_test()
    var left_anchor: Marker2D = playground.get_left_hand_anchor_for_test()
    var right_anchor: Marker2D = playground.get_right_hand_anchor_for_test()
    var left_hold: StaticBody2D = null
    var right_hold: StaticBody2D = null
    var left_distance: float = INF
    var right_distance: float = INF

    assert_not_null(chunk_node)
    assert_not_null(handhold_root)
    assert_not_null(player_body)
    assert_not_null(left_anchor)
    assert_not_null(right_anchor)

    for handhold in handhold_root.get_children():
        assert_true(handhold is StaticBody2D)
        var generated_hold: StaticBody2D = handhold as StaticBody2D
        if generated_hold.global_position.x <= player_body.global_position.x:
            var left_candidate_distance: float = left_anchor.global_position.distance_to(generated_hold.global_position)
            if left_candidate_distance < left_distance:
                left_hold = generated_hold
                left_distance = left_candidate_distance

        if generated_hold.global_position.x >= player_body.global_position.x:
            var right_candidate_distance: float = right_anchor.global_position.distance_to(generated_hold.global_position)
            if right_candidate_distance < right_distance:
                right_hold = generated_hold
                right_distance = right_candidate_distance

    assert_not_null(left_hold)
    assert_not_null(right_hold)
    assert_ne(left_hold, right_hold)
    return [left_hold, right_hold]

func _attach_to_generated_opener_holds(playground: RunSceneScript, attach_left: bool = true, attach_right: bool = true) -> void:
    var starter_holds: Array[StaticBody2D] = _get_generated_opener_hold_pair(playground)
    var left_hold: StaticBody2D = starter_holds[0]
    var right_hold: StaticBody2D = starter_holds[1]

    if attach_left:
        playground.get_controller_for_test().get_attachment_state().attach(
            HandSide.Value.LEFT,
            left_hold.name,
            left_hold.global_position,
            left_hold.get_path()
        )

    if attach_right:
        playground.get_controller_for_test().get_attachment_state().attach(
            HandSide.Value.RIGHT,
            right_hold.name,
            right_hold.global_position,
            right_hold.get_path()
        )

func _get_required_string_meta(node: Node, key: StringName) -> String:
    assert_not_null(node)
    assert_true(node.has_meta(key))
    var raw_value: Variant = node.get_meta(key)
    assert_true(raw_value is String)
    var typed_value: String = raw_value
    return typed_value