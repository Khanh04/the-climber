class_name RunGeneratedSpawnHookupRuntime
extends RefCounted

const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const GeneratedCoinPickupSpawnAdapterScript = preload("res://src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")

func ensure_chunk_spawn_signal_connected(generated_chunk_coordinator: Node, on_generated_chunk_spawned: Callable) -> void:
	Validation.require_condition(on_generated_chunk_spawned.is_valid(), "RunGeneratedSpawnHookupRuntime requires a valid chunk-spawn callback.")
	var typed_coordinator: GeneratedChunkCoordinatorScript = _require_generated_chunk_coordinator(generated_chunk_coordinator)
	if typed_coordinator.chunk_spawned.is_connected(on_generated_chunk_spawned):
		return

	var _chunk_spawn_connect_result: int = typed_coordinator.chunk_spawned.connect(on_generated_chunk_spawned)

func connect_generated_chunk(
	chunk_node: Node2D,
	on_generated_coin_pickup_collected: Callable,
	on_generated_hazard_triggered: Callable
) -> void:
	Validation.require_condition(chunk_node != null, "RunGeneratedSpawnHookupRuntime requires a chunk node.")
	Validation.require_condition(
		on_generated_coin_pickup_collected.is_valid(),
		"RunGeneratedSpawnHookupRuntime requires a valid generated coin pickup callback."
	)
	Validation.require_condition(
		on_generated_hazard_triggered.is_valid(),
		"RunGeneratedSpawnHookupRuntime requires a valid generated hazard callback."
	)
	_connect_generated_pickups(chunk_node, on_generated_coin_pickup_collected)
	_connect_generated_hazards(chunk_node, on_generated_hazard_triggered)

func _connect_generated_pickups(chunk_node: Node2D, on_generated_coin_pickup_collected: Callable) -> void:
	var pickup_root: Node = _require_named_child(chunk_node, ^"Pickups", "RunGeneratedSpawnHookupRuntime generated chunk requires a Pickups root.")
	for pickup_child in pickup_root.get_children():
		Validation.require_condition(
			pickup_child is GeneratedCoinPickupSpawnAdapterScript,
			"RunGeneratedSpawnHookupRuntime generated pickups must use GeneratedCoinPickupSpawnAdapter."
		)
		var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = pickup_child as GeneratedCoinPickupSpawnAdapterScript
		if pickup_spawn.collected.is_connected(on_generated_coin_pickup_collected):
			continue

		var _pickup_connect_result: int = pickup_spawn.collected.connect(on_generated_coin_pickup_collected)

func _connect_generated_hazards(chunk_node: Node2D, on_generated_hazard_triggered: Callable) -> void:
	var hazard_root: Node = _require_named_child(chunk_node, ^"Hazards", "RunGeneratedSpawnHookupRuntime generated chunk requires a Hazards root.")
	for hazard_child in hazard_root.get_children():
		Validation.require_condition(
			hazard_child is GeneratedHazardSpawnAdapterScript,
			"RunGeneratedSpawnHookupRuntime generated hazards must use GeneratedHazardSpawnAdapter."
		)
		var hazard_spawn: GeneratedHazardSpawnAdapterScript = hazard_child as GeneratedHazardSpawnAdapterScript
		var bound_hazard_callback: Callable = on_generated_hazard_triggered.bind(hazard_spawn)
		if hazard_spawn.triggered.is_connected(bound_hazard_callback):
			continue

		var _hazard_connect_result: int = hazard_spawn.triggered.connect(bound_hazard_callback)

func _require_generated_chunk_coordinator(generated_chunk_coordinator: Node) -> GeneratedChunkCoordinatorScript:
	Validation.require_condition(generated_chunk_coordinator != null, "RunGeneratedSpawnHookupRuntime requires a generated chunk coordinator.")
	Validation.require_condition(
		generated_chunk_coordinator is GeneratedChunkCoordinatorScript,
		"RunGeneratedSpawnHookupRuntime requires GeneratedChunkCoordinator."
	)
	return generated_chunk_coordinator as GeneratedChunkCoordinatorScript

func _require_named_child(chunk_node: Node2D, child_name: NodePath, message: String) -> Node:
	var child_node: Node = chunk_node.get_node_or_null(child_name)
	Validation.require_condition(child_node != null, message)
	return child_node