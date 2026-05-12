extends GutTest

const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")

var _contacted_body: Node = null

func test_chaser_scene_wires_required_nodes_and_defaults() -> void:
	var chaser: ChaserKillZoneScript = await _instantiate_chaser()

	assert_not_null(chaser.get_node_or_null("CollisionShape2D"))
	assert_not_null(chaser.get_node_or_null("Visual"))
	assert_true(chaser.monitoring)
	assert_true(chaser.monitorable)
	assert_gt(chaser.get_collision_width_pixels(), 0.0)
	assert_eq(chaser.get_collision_height_pixels(), chaser.kill_zone_height_pixels)

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