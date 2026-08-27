extends Node2D

const SpriteFrameSequenceLoaderScript = preload("res://src/core/sprite_frame_sequence_loader.gd")

const FRAME_PATH_FORMAT: String = "res://assets/PNG/UI/run_sence/obstacles/wind_animation/wind/frame_%02d.png"
const FRAME_COUNT: int = 50
const ANIMATION_NAME: StringName = &"wind"
const FRAMES_PER_SECOND: float = 30.0

func _ready() -> void:
	var animated_sprite: AnimatedSprite2D = get_node("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrameSequenceLoaderScript.build_looping_animation(
			FRAME_PATH_FORMAT,
			FRAME_COUNT,
			ANIMATION_NAME,
			FRAMES_PER_SECOND
		)
	animated_sprite.animation = ANIMATION_NAME
	animated_sprite.play()
