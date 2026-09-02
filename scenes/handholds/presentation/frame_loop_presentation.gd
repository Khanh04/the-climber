extends Node2D

## Looping frame-sequence presentation for handhold scenes. Configure the frame
## path format, count, name, and speed per scene; the SpriteFrames are built once
## on ready. Mirrors scenes/hazards/presentation/wind_loop_presentation.gd but
## parameterised so multiple handhold types can share it.

const SpriteFrameSequenceLoaderScript = preload("res://src/core/sprite_frame_sequence_loader.gd")

@export var frame_path_format: String = ""
@export var frame_count: int = 0
@export var animation_name: StringName = &"loop"
@export var frames_per_second: float = 12.0

func _ready() -> void:
	var animated_sprite: AnimatedSprite2D = get_node("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrameSequenceLoaderScript.build_looping_animation(
			frame_path_format,
			frame_count,
			animation_name,
			frames_per_second
		)
	animated_sprite.animation = animation_name
	animated_sprite.play()
