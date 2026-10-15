class_name SkillContext
extends RefCounted

## Everything an active character skill may read or act on during one frame.

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")

var controller: ClimbPrototypeControllerScript
var player: PlayerCharacterScript
var stamina: StaminaRuntimeScript
## Zero when the player is not aiming.
var aim_vector: Vector2
var handholds: Array[Node2D]
var grab_radius_pixels: float

func _init(
	controller_value: ClimbPrototypeControllerScript,
	player_value: PlayerCharacterScript,
	stamina_value: StaminaRuntimeScript,
	aim_vector_value: Vector2,
	handholds_value: Array[Node2D],
	grab_radius_pixels_value: float
) -> void:
	Validation.require_condition(controller_value != null, "SkillContext requires a climb controller.")
	Validation.require_condition(player_value != null, "SkillContext requires a player character.")
	Validation.require_condition(stamina_value != null, "SkillContext requires a stamina runtime.")
	Validation.require_condition(grab_radius_pixels_value > 0.0, "SkillContext grab radius must be positive.")
	controller = controller_value
	player = player_value
	stamina = stamina_value
	aim_vector = aim_vector_value
	handholds = handholds_value
	grab_radius_pixels = grab_radius_pixels_value

func get_hand_midpoint() -> Vector2:
	return (player.get_left_hand_anchor_global_position() + player.get_right_hand_anchor_global_position()) * 0.5
