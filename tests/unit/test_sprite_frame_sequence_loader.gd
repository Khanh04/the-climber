extends GutTest

const SpriteFrameSequenceLoaderScript = preload("res://src/core/sprite_frame_sequence_loader.gd")

func test_build_looping_animation_loads_all_frames_with_loop_and_speed() -> void:
	var frames: SpriteFrames = SpriteFrameSequenceLoaderScript.build_looping_animation(
		"res://assets/PNG/UI/run_scene/wind_animation/wind/frame_%02d.png",
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
