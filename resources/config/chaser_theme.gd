class_name ChaserTheme
extends Resource

@export var theme_id: StringName = &"rising_void"
@export var audio_loop_stream: AudioStream
@export var chaser_sprite_frames: SpriteFrames
@export var base_fill_color: Color = Color(0.16, 0.09, 0.12, 1.0)
@export var high_pressure_fill_color: Color = Color(0.36, 0.10, 0.08, 1.0)
@export var glow_color: Color = Color(0.84, 0.22, 0.14, 1.0)
@export var crest_color: Color = Color(1.0, 0.57, 0.30, 1.0)
@export var glow_extra_width_pixels: float = 160.0
@export var glow_extra_height_pixels: float = 112.0
@export var crest_height_pixels: float = 40.0
@export var crest_side_inset_pixels: float = 28.0
@export var glow_min_alpha: float = 0.08
@export var glow_max_alpha: float = 0.34
@export var crest_min_alpha: float = 0.14
@export var crest_max_alpha: float = 0.76
@export var pulse_min_frequency_hz: float = 0.65
@export var pulse_max_frequency_hz: float = 1.9
@export var audio_volume_curve_exponent: float = 0.5
@export var audio_pitch_curve_exponent: float = 1.35
@export var glow_max_scale_delta: float = 0.05
@export var crest_max_scale_delta: float = 0.18
@export var crest_max_lift_pixels: float = 10.0

func is_valid() -> bool:
	return not theme_id.is_empty() \
		and audio_loop_stream != null \
		and chaser_sprite_frames != null \
		and glow_extra_width_pixels >= 0.0 \
		and glow_extra_height_pixels >= 0.0 \
		and crest_height_pixels > 0.0 \
		and crest_side_inset_pixels >= 0.0 \
		and glow_min_alpha >= 0.0 \
		and glow_min_alpha <= 1.0 \
		and glow_max_alpha >= glow_min_alpha \
		and glow_max_alpha <= 1.0 \
		and crest_min_alpha >= 0.0 \
		and crest_min_alpha <= 1.0 \
		and crest_max_alpha >= crest_min_alpha \
		and crest_max_alpha <= 1.0 \
		and pulse_min_frequency_hz > 0.0 \
		and pulse_max_frequency_hz >= pulse_min_frequency_hz \
		and audio_volume_curve_exponent > 0.0 \
		and audio_pitch_curve_exponent > 0.0 \
		and glow_max_scale_delta >= 0.0 \
		and crest_max_scale_delta >= 0.0 \
		and crest_max_lift_pixels >= 0.0

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not theme_id.is_empty(), "Chaser theme id cannot be empty.")
	Validation.require_condition(audio_loop_stream != null, "Chaser theme requires an audio loop stream.")
	Validation.require_condition(chaser_sprite_frames != null, "Chaser theme requires chaser sprite frames.")
	Validation.require_condition(glow_extra_width_pixels >= 0.0, "Chaser theme glow extra width cannot be negative.")
	Validation.require_condition(glow_extra_height_pixels >= 0.0, "Chaser theme glow extra height cannot be negative.")
	Validation.require_condition(crest_height_pixels > 0.0, "Chaser theme crest height must be positive.")
	Validation.require_condition(crest_side_inset_pixels >= 0.0, "Chaser theme crest side inset cannot be negative.")
	Validation.require_condition(glow_min_alpha >= 0.0 and glow_min_alpha <= 1.0, "Chaser theme glow minimum alpha must be between 0.0 and 1.0.")
	Validation.require_condition(glow_max_alpha >= glow_min_alpha and glow_max_alpha <= 1.0, "Chaser theme glow maximum alpha must be between the minimum alpha and 1.0.")
	Validation.require_condition(crest_min_alpha >= 0.0 and crest_min_alpha <= 1.0, "Chaser theme crest minimum alpha must be between 0.0 and 1.0.")
	Validation.require_condition(crest_max_alpha >= crest_min_alpha and crest_max_alpha <= 1.0, "Chaser theme crest maximum alpha must be between the minimum alpha and 1.0.")
	Validation.require_condition(pulse_min_frequency_hz > 0.0, "Chaser theme pulse minimum frequency must be positive.")
	Validation.require_condition(pulse_max_frequency_hz >= pulse_min_frequency_hz, "Chaser theme pulse maximum frequency must be at least the minimum frequency.")
	Validation.require_condition(audio_volume_curve_exponent > 0.0, "Chaser theme audio volume curve exponent must be positive.")
	Validation.require_condition(audio_pitch_curve_exponent > 0.0, "Chaser theme audio pitch curve exponent must be positive.")
	Validation.require_condition(glow_max_scale_delta >= 0.0, "Chaser theme glow max scale delta cannot be negative.")
	Validation.require_condition(crest_max_scale_delta >= 0.0, "Chaser theme crest max scale delta cannot be negative.")
	Validation.require_condition(crest_max_lift_pixels >= 0.0, "Chaser theme crest max lift cannot be negative.")

func evaluate_audio_volume_intensity_ratio(intensity_ratio: float) -> float:
	Validation.require_condition(intensity_ratio >= 0.0 and intensity_ratio <= 1.0, "Chaser theme audio volume intensity ratio must be between 0.0 and 1.0.")
	return pow(intensity_ratio, audio_volume_curve_exponent)

func evaluate_audio_pitch_intensity_ratio(intensity_ratio: float) -> float:
	Validation.require_condition(intensity_ratio >= 0.0 and intensity_ratio <= 1.0, "Chaser theme audio pitch intensity ratio must be between 0.0 and 1.0.")
	return pow(intensity_ratio, audio_pitch_curve_exponent)
