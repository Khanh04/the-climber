class_name RunWorldSurfaceConfigurator
extends RefCounted

const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const GeneratedHandholdAdapterScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const HandholdSurfaceProfileScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeDefinitionScript = preload("res://resources/config/handhold_type_definition.gd")
const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RunGameplayNodeRefsScript = preload("res://src/gameplay/run/run_gameplay_node_refs.gd")
const RunLaunchModeScript = preload("res://src/core/run_launch_mode.gd")

func configure_surface(
	gameplay_nodes: RefCounted,
	run_hud: Control,
	launch_mode: int,
	climb_tuning: Resource,
	generation_tuning: Resource,
	tutorial_handhold_group_name: StringName
) -> void:
	Validation.require_condition(gameplay_nodes != null, "RunWorldSurfaceConfigurator requires gameplay nodes.")
	Validation.require_condition(gameplay_nodes is RunGameplayNodeRefsScript, "RunWorldSurfaceConfigurator requires RunGameplayNodeRefs.")
	Validation.require_condition(run_hud != null, "RunWorldSurfaceConfigurator requires RunHud.")
	Validation.require_condition(climb_tuning != null, "RunWorldSurfaceConfigurator requires climb tuning.")
	Validation.require_condition(climb_tuning is ClimbPrototypeTuningScript, "RunWorldSurfaceConfigurator requires ClimbPrototypeTuning.")
	Validation.require_condition(generation_tuning != null, "RunWorldSurfaceConfigurator requires generation tuning.")
	Validation.require_condition(generation_tuning is GenerationTuningScript, "RunWorldSurfaceConfigurator requires GenerationTuning.")
	RunLaunchModeScript.assert_valid(launch_mode)

	var typed_gameplay_nodes: RunGameplayNodeRefsScript = gameplay_nodes as RunGameplayNodeRefsScript
	var typed_climb_tuning: ClimbPrototypeTuningScript = climb_tuning as ClimbPrototypeTuningScript
	var typed_generation_tuning: GenerationTuningScript = generation_tuning as GenerationTuningScript
	typed_gameplay_nodes.assert_valid()
	typed_climb_tuning.assert_valid()
	typed_generation_tuning.assert_valid()
	Validation.require_condition(not String(tutorial_handhold_group_name).is_empty(), "RunWorldSurfaceConfigurator requires a tutorial handhold group name.")

	_configure_authored_handholds(typed_gameplay_nodes, typed_climb_tuning, typed_generation_tuning)
	_apply_launch_mode_surface(typed_gameplay_nodes, run_hud, launch_mode, typed_climb_tuning, tutorial_handhold_group_name)

func _configure_authored_handholds(
	gameplay_nodes: RunGameplayNodeRefsScript,
	climb_tuning: ClimbPrototypeTuningScript,
	generation_tuning: GenerationTuningScript
) -> void:
	for child in gameplay_nodes.starter_handholds_root.get_children():
		Validation.require_condition(child is Node, "RunWorldSurfaceConfigurator handhold roots must contain nodes.")
		var handhold_node: Node = child
		if not handhold_node.is_in_group(climb_tuning.handhold_group_name):
			continue

		Validation.require_condition(
			handhold_node is StaticBody2D,
			"RunWorldSurfaceConfigurator authored handholds must be StaticBody2D instances."
		)
		if handhold_node is GeneratedHandholdAdapterScript:
			continue

		var normal_definition: HandholdTypeDefinitionScript = generation_tuning.get_required_handhold_definition(HandholdTypeScript.Value.NORMAL)
		var normal_surface_profile: HandholdSurfaceProfileScript = normal_definition.surface_profile as HandholdSurfaceProfileScript
		handhold_node.set_meta(&"stamina_drain_multiplier", normal_surface_profile.stamina_drain_multiplier)
		handhold_node.set_meta(&"handhold_type", HandholdTypeScript.to_label(HandholdTypeScript.Value.NORMAL))
		handhold_node.set_meta(&"definition_id", String(normal_definition.definition_id))

func _apply_launch_mode_surface(
	gameplay_nodes: RunGameplayNodeRefsScript,
	run_hud: Control,
	launch_mode: int,
	climb_tuning: ClimbPrototypeTuningScript,
	tutorial_handhold_group_name: StringName
) -> void:
	var tutorial_mode_enabled: bool = launch_mode == RunLaunchModeScript.Value.TUTORIAL
	gameplay_nodes.generated_chunk_coordinator.visible = not tutorial_mode_enabled
	run_hud.visible = not tutorial_mode_enabled
	_set_tutorial_handholds_enabled(gameplay_nodes, tutorial_mode_enabled, climb_tuning, tutorial_handhold_group_name)

func _set_tutorial_handholds_enabled(
	gameplay_nodes: RunGameplayNodeRefsScript,
	enabled: bool,
	climb_tuning: ClimbPrototypeTuningScript,
	tutorial_handhold_group_name: StringName
) -> void:
	for child in gameplay_nodes.starter_handholds_root.get_children():
		Validation.require_condition(child is Node, "RunWorldSurfaceConfigurator handhold roots must contain nodes when toggling tutorial handholds.")
		var handhold_node: Node = child
		if not handhold_node.is_in_group(tutorial_handhold_group_name):
			continue

		Validation.require_condition(handhold_node is StaticBody2D, "RunWorldSurfaceConfigurator tutorial handholds must be StaticBody2D instances.")
		var tutorial_handhold: StaticBody2D = handhold_node as StaticBody2D
		if enabled:
			if not tutorial_handhold.is_in_group(climb_tuning.handhold_group_name):
				tutorial_handhold.add_to_group(climb_tuning.handhold_group_name)
		else:
			if tutorial_handhold.is_in_group(climb_tuning.handhold_group_name):
				tutorial_handhold.remove_from_group(climb_tuning.handhold_group_name)

		tutorial_handhold.visible = enabled
		_set_handhold_collision_enabled(tutorial_handhold, enabled)

func _set_handhold_collision_enabled(handhold_body: StaticBody2D, enabled: bool) -> void:
	Validation.require_condition(handhold_body != null, "RunWorldSurfaceConfigurator requires a handhold body before toggling collisions.")

	for child in handhold_body.get_children():
		if child is CollisionShape2D:
			var collision_shape: CollisionShape2D = child as CollisionShape2D
			collision_shape.disabled = not enabled