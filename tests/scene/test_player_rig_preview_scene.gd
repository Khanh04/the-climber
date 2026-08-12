extends GutTest

const PlayerRigPreviewScript = preload("res://src/debug/player_rig_preview.gd")

func test_player_rig_preview_scene_instantiates_authored_and_runtime_rigs() -> void:
	var scene: PackedScene = load("res://scenes/player/player_rig_preview.tscn")
	var preview_node: Node = scene.instantiate()
	var preview: PlayerRigPreviewScript = preview_node as PlayerRigPreviewScript

	assert_not_null(preview)
	add_child_autofree(preview)
	await get_tree().process_frame

	assert_not_null(preview.get_node_or_null("AuthoredRestPoseAnchor"))
	assert_not_null(preview.get_node_or_null("RuntimeDrivenPoseAnchor"))
	assert_not_null(preview.get_authored_rest_rig_for_test())
	assert_not_null(preview.get_runtime_driven_rig_for_test())
	assert_eq(preview.get_authored_rest_rig_for_test().get_parent(), preview.get_node("AuthoredRestPoseAnchor"))
	assert_eq(preview.get_runtime_driven_rig_for_test().get_parent(), preview.get_node("RuntimeDrivenPoseAnchor"))

func test_player_rig_preview_scene_applies_pose_delta_only_to_runtime_preview() -> void:
	var scene: PackedScene = load("res://scenes/player/player_rig_preview.tscn")
	var preview_node: Node = scene.instantiate()
	var preview: PlayerRigPreviewScript = preview_node as PlayerRigPreviewScript

	assert_not_null(preview)
	add_child_autofree(preview)
	await get_tree().process_frame

	var authored_lower_body: Bone2D = preview.get_authored_lower_body_bone_for_test()
	var runtime_lower_body: Bone2D = preview.get_runtime_lower_body_bone_for_test()
	var authored_starting_rotation: float = authored_lower_body.rotation
	var runtime_starting_rotation: float = runtime_lower_body.rotation

	assert_not_null(authored_lower_body)
	assert_not_null(runtime_lower_body)

	preview.lower_body_delta_degrees = 18.0
	await get_tree().process_frame

	assert_almost_eq(authored_lower_body.rotation, authored_starting_rotation, 0.001)
	assert_almost_eq(runtime_lower_body.rotation - runtime_starting_rotation, deg_to_rad(18.0), 0.001)