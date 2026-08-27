extends GutTest

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const GeneratedHandholdAdapterScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const RunGeneratedHandholdRuntimeScript = preload("res://src/gameplay/run/run_generated_handhold_runtime.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")

func test_advance_attached_lifecycle_preserves_right_only_attachment_when_hold_does_not_break() -> void:
	var fixture: Node2D = await _build_fixture(2.0, false, Vector2.ZERO)
	var player: PlayerCharacterScript = fixture.get_node("Player") as PlayerCharacterScript
	var generated_hold: GeneratedHandholdAdapterScript = fixture.get_node("GeneratedHold") as GeneratedHandholdAdapterScript
	var controller: ClimbPrototypeControllerScript = _create_controller()
	var runtime: RunGeneratedHandholdRuntimeScript = RunGeneratedHandholdRuntimeScript.new()

	controller.get_attachment_state().attach(
		HandSideScript.Value.RIGHT,
		generated_hold.hold_id,
		generated_hold.global_position,
		generated_hold.get_path()
	)
	runtime.notify_hand_attached_for_path(
		generated_hold.get_path(),
		Callable(self, "_resolve_generated_handhold").bind(fixture)
	)

	runtime.advance_attached_lifecycle(
		controller,
		1.0 / 60.0,
		Callable(self, "_resolve_generated_handhold").bind(fixture)
	)

	assert_not_null(player)
	assert_eq(controller.get_attachment_state().get_attached_hand_count(), 1)
	assert_true(controller.get_attachment_state().is_attached(HandSideScript.Value.RIGHT))

func test_resolve_attachment_changes_applies_release_impulse_to_player_body() -> void:
	var release_impulse: Vector2 = Vector2(18.0, -6.0)
	var fixture: Node2D = await _build_fixture(0.0, false, release_impulse)
	var player: PlayerCharacterScript = fixture.get_node("Player") as PlayerCharacterScript
	var generated_hold: GeneratedHandholdAdapterScript = fixture.get_node("GeneratedHold") as GeneratedHandholdAdapterScript
	var controller: ClimbPrototypeControllerScript = _create_controller()
	var runtime: RunGeneratedHandholdRuntimeScript = RunGeneratedHandholdRuntimeScript.new()
	var starting_linear_velocity: Vector2 = player.get_body_linear_velocity()

	controller.get_attachment_state().attach(
		HandSideScript.Value.LEFT,
		generated_hold.hold_id,
		generated_hold.global_position,
		generated_hold.get_path()
	)
	runtime.notify_hand_attached_for_path(
		generated_hold.get_path(),
		Callable(self, "_resolve_generated_handhold").bind(fixture)
	)
	controller.get_attachment_state().release(HandSideScript.Value.LEFT)

	runtime.resolve_attachment_changes(
		controller,
		player,
		true,
		generated_hold.get_path(),
		false,
		NodePath(),
		Callable(self, "_resolve_generated_handhold").bind(fixture)
	)

	assert_eq(player.get_body_linear_velocity() - starting_linear_velocity, release_impulse)

func _build_fixture(break_after_attach_seconds: float, breaks_on_release: bool, release_impulse: Vector2) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = &"GeneratedHandholdFixture"
	add_child_autofree(root)

	var player_scene: PackedScene = load("res://scenes/player/player_character.tscn")
	var player_node: Node = player_scene.instantiate()
	assert_true(player_node is PlayerCharacterScript)
	var player: PlayerCharacterScript = player_node as PlayerCharacterScript
	player.name = &"Player"
	root.add_child(player)

	var generated_hold: GeneratedHandholdAdapterScript = GeneratedHandholdAdapterScript.new()
	generated_hold.name = &"GeneratedHold"
	generated_hold.configure_handhold(
		&"generated_hold",
		&"generated_hold_definition",
		0,
		Vector2(180.0, 220.0),
		Vector2(72.0, 18.0),
		1.0,
		break_after_attach_seconds,
		breaks_on_release,
		release_impulse,
		preload("res://resources/config/handhold_presentation_catalog.tres").get_required_definition(0)
	)
	root.add_child(generated_hold)

	await get_tree().process_frame
	return root

func _create_controller() -> ClimbPrototypeControllerScript:
	return ClimbPrototypeControllerScript.new(
		ClimbPrototypeTuningScript.new(),
		StaminaRuntimeScript.new(StaminaTuningScript.new())
	)

func _resolve_generated_handhold(hold_path: NodePath, root: Node) -> GeneratedHandholdAdapterScript:
	if hold_path.is_empty():
		return null

	var hold_node: Node = root.get_node_or_null(hold_path)
	if hold_node == null or not hold_node is GeneratedHandholdAdapterScript:
		return null

	return hold_node as GeneratedHandholdAdapterScript
