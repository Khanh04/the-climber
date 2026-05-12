extends GutTest

const ChaserContactServiceScript = preload("res://src/gameplay/chaser/chaser_contact_service.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")
const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")

func test_chaser_contact_releases_attachments_and_ends_run_without_rescue() -> void:
	var player: PlayerCharacterScript = await _instantiate_player()
	var controller := ClimbPrototypeControllerScript.new(ClimbPrototypeTuningScript.new(), StaminaRuntimeScript.new(StaminaTuningScript.new()))
	var session := RunSessionScript.new()
	var service := ChaserContactServiceScript.new()

	session.start_run()
	controller.get_attachment_state().attach(HandSideScript.Value.LEFT, &"test_hold_left", Vector2(100.0, 120.0), NodePath("Holds/TestLeft"))
	controller.get_attachment_state().attach(HandSideScript.Value.RIGHT, &"test_hold_right", Vector2(140.0, 120.0), NodePath("Holds/TestRight"))

	service.resolve(controller, player, session)

	assert_eq(controller.get_attachment_state().get_attached_hand_count(), 0)
	assert_eq(player.get_physics_mode(), PlayerPhysicsModeScript.falling_ragdoll())
	assert_eq(session.get_state(), RunStateScript.Value.ENDED)
	assert_true(session.has_end_reason())
	assert_eq(session.get_end_reason(), RunEndReasonScript.Value.CHASER_CONTACT)

func _instantiate_player() -> PlayerCharacterScript:
	var scene: PackedScene = load("res://scenes/player/player_character.tscn")
	var player_node: Node = scene.instantiate()
	var player: PlayerCharacterScript = player_node as PlayerCharacterScript

	assert_not_null(player)
	add_child_autofree(player)
	await get_tree().process_frame

	return player