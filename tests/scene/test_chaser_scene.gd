extends GutTest

const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")

var _contacted_body: Node = null

func test_chaser_scene_wires_required_nodes_and_defaults() -> void:
	var chaser: ChaserKillZoneScript = await _instantiate_chaser()
	var audio_player: AudioStreamPlayer2D = chaser.get_node("IntensityAudioPlayer") as AudioStreamPlayer2D

	assert_not_null(chaser.get_node_or_null("CollisionShape2D"))
	assert_not_null(chaser.get_node_or_null("Visual"))
	assert_not_null(chaser.get_node_or_null("IntensityAudioPlayer"))
	assert_not_null(audio_player)
	assert_true(chaser.monitoring)
	assert_true(chaser.monitorable)
	assert_gt(chaser.get_collision_width_pixels(), 0.0)
	assert_eq(chaser.get_collision_height_pixels(), chaser.kill_zone_height_pixels)
	assert_eq(chaser.get_feedback_intensity_ratio(), 0.0)
	assert_not_null(audio_player.stream)
	assert_false(audio_player.playing)

func test_chaser_scene_reset_and_rise_use_typed_geometry_contract() -> void:
	var chaser: ChaserKillZoneScript = await _instantiate_chaser()

	chaser.reset_to_player_position(1500.0, 100.0, 540.0, 1080.0)
	assert_eq(chaser.global_position.x, 540.0)
	assert_eq(chaser.get_collision_width_pixels(), 1336.0)
	assert_eq(chaser.global_position.y, 1500.0 + (chaser.chaser_tuning.initial_spawn_offset_meters * 100.0) + (chaser.kill_zone_height_pixels * 0.5))

	var start_y: float = chaser.global_position.y
	chaser.advance_rise(2.5, 100.0, 2.0)

	assert_eq(chaser.global_position.y, start_y - 500.0)

func test_chaser_scene_emits_contact_signal_for_player_body() -> void:
	var chaser: ChaserKillZoneScript = await _instantiate_chaser()
	var player: PlayerCharacterScript = await _instantiate_player()

	_contacted_body = null
	var connect_result: int = chaser.connect(&"chaser_contacted", Callable(self, "_capture_contacted_body"))
	assert_eq(connect_result, OK)

	chaser.call("_on_body_entered", player.get_player_body())

	assert_eq(_contacted_body, player.get_player_body())

func test_chaser_scene_feedback_updates_visual_alpha_and_audio_properties() -> void:
	var chaser: ChaserKillZoneScript = await _instantiate_chaser()
	var audio_player: AudioStreamPlayer2D = chaser.get_node("IntensityAudioPlayer") as AudioStreamPlayer2D
	var feedback_snapshot := ChaserFeedbackSnapshotScript.new(
		ChaserPacingModelScript.PaceState.CAMPING,
		1.0,
		chaser.chaser_tuning.max_rise_speed_meters_per_second,
		1.0
	)

	assert_not_null(audio_player)
	chaser.reset_to_player_position(1500.0, 100.0, 540.0, 1080.0)
	chaser.sync_feedback(feedback_snapshot, 1500.0, 100.0)

	assert_eq(chaser.get_feedback_intensity_ratio(), 1.0)
	assert_not_null(audio_player.stream)
	assert_false(audio_player.playing)
	assert_true(is_equal_approx((chaser.get_node("Visual") as Polygon2D).color.a, chaser.chaser_tuning.max_visual_alpha))
	assert_true(is_equal_approx(audio_player.volume_db, chaser.chaser_tuning.max_audio_volume_db))
	assert_true(is_equal_approx(audio_player.pitch_scale, chaser.chaser_tuning.max_audio_pitch_scale))

func test_chaser_scene_proximity_intensity_increases_when_player_is_close() -> void:
	var chaser: ChaserKillZoneScript = await _instantiate_chaser()
	var feedback_snapshot := ChaserFeedbackSnapshotScript.new(
		ChaserPacingModelScript.PaceState.RAPID_CLIMB,
		10.0,
		chaser.chaser_tuning.min_rise_speed_meters_per_second,
		0.0
	)

	chaser.reset_to_player_position(1500.0, 100.0, 540.0, 1080.0)

	var far_player_y: float = chaser.get_top_edge_y() - (chaser.chaser_tuning.far_distance_for_min_intensity_meters * 100.0)
	var near_player_y: float = chaser.get_top_edge_y() - (chaser.chaser_tuning.near_distance_for_max_intensity_meters * 100.0)

	chaser.sync_feedback(feedback_snapshot, far_player_y, 100.0)
	assert_eq(chaser.get_feedback_intensity_ratio(), 0.0)

	chaser.sync_feedback(feedback_snapshot, near_player_y, 100.0)
	assert_eq(chaser.get_feedback_intensity_ratio(), 1.0)

func _instantiate_chaser() -> ChaserKillZoneScript:
	var scene: PackedScene = load("res://scenes/chaser/chaser_kill_zone.tscn")
	var chaser_node: Node = scene.instantiate()
	var chaser: ChaserKillZoneScript = chaser_node as ChaserKillZoneScript

	assert_not_null(chaser)
	add_child_autofree(chaser)
	await get_tree().process_frame

	return chaser

func _instantiate_player() -> PlayerCharacterScript:
	var scene: PackedScene = load("res://scenes/player/player_character.tscn")
	var player_node: Node = scene.instantiate()
	var player: PlayerCharacterScript = player_node as PlayerCharacterScript

	assert_not_null(player)
	add_child_autofree(player)
	await get_tree().process_frame

	return player

func _capture_contacted_body(body: Node) -> void:
	_contacted_body = body