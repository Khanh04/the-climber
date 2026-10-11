extends GutTest

const SpriteFrameSequenceLoaderScript = preload("res://src/core/sprite_frame_sequence_loader.gd")

func test_build_looping_animation_loads_all_frames_with_loop_and_speed() -> void:
	var frames: SpriteFrames = SpriteFrameSequenceLoaderScript.build_looping_animation(
		"res://assets/assets_animated/wind/frame_%02d.png",
		50,
		&"wind",
		24.0
	)

	assert_not_null(frames)
	assert_true(frames.has_animation(&"wind"))
	assert_eq(frames.get_frame_count(&"wind"), 50)
	assert_true(frames.get_animation_loop(&"wind"))
	assert_eq(frames.get_animation_speed(&"wind"), 24.0)
	assert_not_null(frames.get_frame_texture(&"wind", 0))

func test_moved_handhold_animation_sequences_load_on_ready() -> void:
	for scene_path: String in ["res://scenes/handholds/presentation/burn.tscn", "res://scenes/handholds/presentation/rest.tscn"]:
		var scene: PackedScene = load(scene_path) as PackedScene
		var presentation: Node = scene.instantiate()
		add_child_autofree(presentation)
		var sprite: AnimatedSprite2D = presentation.get_node("AnimatedSprite2D") as AnimatedSprite2D
		var is_burn: bool = scene_path.ends_with("burn.tscn")
		var animation: StringName = &"burn" if is_burn else &"rest"
		var expected_count: int = 12 if is_burn else 24
		assert_eq(sprite.sprite_frames.get_frame_count(animation), expected_count)
		assert_true(sprite.is_playing())
		assert_not_null(sprite.sprite_frames.get_frame_texture(animation, expected_count - 1))