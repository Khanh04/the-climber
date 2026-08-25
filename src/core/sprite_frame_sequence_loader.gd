class_name SpriteFrameSequenceLoader
extends RefCounted

## Builds a looping SpriteFrames animation from a zero-padded, 1-indexed
## numbered texture sequence (e.g. "res://.../frame_%02d.png" for frame_01
## through frame_NN).
static func build_looping_animation(frame_path_format: String, frame_count: int, animation_name: StringName, frames_per_second: float) -> SpriteFrames:
	Validation.require_condition(frame_count > 0, "Sprite frame sequence must include at least one frame.")
	Validation.require_condition(frames_per_second > 0.0, "Sprite frame sequence speed must be positive.")

	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, frames_per_second)
	for frame_index in range(1, frame_count + 1):
		var frame_path: String = frame_path_format % frame_index
		var texture: Texture2D = load(frame_path) as Texture2D
		Validation.require_condition(texture != null, "Missing sprite frame texture: %s" % frame_path)
		frames.add_frame(animation_name, texture)

	return frames
