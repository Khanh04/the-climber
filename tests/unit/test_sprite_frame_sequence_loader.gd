extends GutTest

const SpriteFrameSequenceLoaderScript = preload("res://src/core/sprite_frame_sequence_loader.gd")

func test_build_looping_animation_loads_all_frames_with_loop_and_speed() -> void:
	var frames: SpriteFrames = SpriteFrameSequenceLoaderScript.build_looping_animation(
		"res://assets/PNG/UI/run_scene/buff_point/buff_animation/frame_%02d.png",
		48,
		&"buff",
		24.0
	)

	assert_not_null(frames)
	assert_true(frames.has_animation(&"buff"))
	assert_eq(frames.get_frame_count(&"buff"), 48)
	assert_true(frames.get_animation_loop(&"buff"))
	assert_eq(frames.get_animation_speed(&"buff"), 24.0)
	assert_not_null(frames.get_frame_texture(&"buff", 0))
