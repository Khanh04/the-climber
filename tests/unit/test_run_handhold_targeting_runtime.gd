extends GutTest

const GeneratedHandholdAdapterScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RunHandholdTargetingRuntimeScript = preload("res://src/gameplay/run/run_handhold_targeting_runtime.gd")

func test_find_nearest_handhold_returns_closest_generated_target_with_runtime_metadata() -> void:
	var root: Node2D = Node2D.new()
	root.name = &"TargetingFixture"
	add_child_autofree(root)

	var starter_handholds_root: Node2D = Node2D.new()
	starter_handholds_root.name = &"Handholds"
	root.add_child(starter_handholds_root)

	var farther_hold: StaticBody2D = StaticBody2D.new()
	farther_hold.name = &"FartherHold"
	farther_hold.global_position = Vector2(164.0, 120.0)
	farther_hold.set_meta(&"stamina_drain_multiplier", 1.6)
	farther_hold.set_meta(&"handhold_type", HandholdTypeScript.to_label(HandholdTypeScript.Value.BURN))
	root.add_child(farther_hold)

	var generated_hold: GeneratedHandholdAdapterScript = GeneratedHandholdAdapterScript.new()
	generated_hold.name = &"GeneratedHold"
	generated_hold.configure_handhold(
		&"generated_hold",
		&"generated_hold_definition",
		HandholdTypeScript.Value.BOOST,
		Vector2(136.0, 120.0),
		Vector2(72.0, 18.0),
		1.35,
		0.0,
		false,
		Vector2.ZERO,
		preload("res://resources/config/handhold_presentation_catalog.tres").get_required_definition(HandholdTypeScript.Value.BOOST)
	)
	root.add_child(generated_hold)
	await get_tree().process_frame

	var runtime: RunHandholdTargetingRuntimeScript = RunHandholdTargetingRuntimeScript.new()
	var target: HandholdTargetScript = runtime.find_nearest_handhold(
		Vector2(120.0, 120.0),
		[farther_hold, generated_hold],
		64.0,
		starter_handholds_root,
		GenerationTuningScript.new()
	)

	assert_not_null(target)
	assert_eq(target.hold_id, &"GeneratedHold")
	assert_eq(target.hold_path, generated_hold.get_path())
	assert_eq(target.stamina_drain_multiplier, 1.35)
	assert_eq(target.handhold_type, HandholdTypeScript.Value.BOOST)

func test_find_nearest_handhold_uses_normal_definition_for_authored_starter_holds() -> void:
	var root: Node2D = Node2D.new()
	root.name = &"StarterTargetingFixture"
	add_child_autofree(root)

	var starter_handholds_root: Node2D = Node2D.new()
	starter_handholds_root.name = &"Handholds"
	root.add_child(starter_handholds_root)

	var starter_hold: StaticBody2D = StaticBody2D.new()
	starter_hold.name = &"StarterHold"
	starter_hold.global_position = Vector2(88.0, 96.0)
	starter_handholds_root.add_child(starter_hold)
	await get_tree().process_frame

	var generation_tuning: GenerationTuningScript = GenerationTuningScript.new()
	var normal_definition: HandholdTypeDefinitionScript = generation_tuning.get_required_handhold_definition(HandholdTypeScript.Value.NORMAL)
	assert_true(normal_definition.surface_profile is HandholdSurfaceProfileScript)
	var normal_surface_profile: HandholdSurfaceProfileScript = normal_definition.surface_profile as HandholdSurfaceProfileScript
	var runtime: RunHandholdTargetingRuntimeScript = RunHandholdTargetingRuntimeScript.new()
	var target: HandholdTargetScript = runtime.find_nearest_handhold(
		Vector2(64.0, 96.0),
		[starter_hold],
		32.0,
		starter_handholds_root,
		generation_tuning
	)

	assert_not_null(target)
	assert_eq(target.hold_id, &"StarterHold")
	assert_eq(target.hold_path, starter_hold.get_path())
	assert_eq(target.stamina_drain_multiplier, normal_surface_profile.stamina_drain_multiplier)
	assert_eq(target.handhold_type, HandholdTypeScript.Value.NORMAL)
