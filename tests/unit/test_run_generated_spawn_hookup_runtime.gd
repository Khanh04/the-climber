extends GutTest

const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const GeneratedCoinPickupSpawnAdapterScript = preload("res://src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd")
const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")
const RunGeneratedSpawnHookupRuntimeScript = preload("res://src/gameplay/run/run_generated_spawn_hookup_runtime.gd")

var _recorded_chunk_spawn_count: int = 0
var _recorded_coin_socket_id: StringName = StringName()
var _recorded_coin_amount: int = 0
var _recorded_coin_body: Node = null
var _recorded_hazard_body: Node = null
var _recorded_hazard_spawn: GeneratedHazardSpawnAdapterScript = null

func before_each() -> void:
	_recorded_chunk_spawn_count = 0
	_recorded_coin_socket_id = StringName()
	_recorded_coin_amount = 0
	_recorded_coin_body = null
	_recorded_hazard_body = null
	_recorded_hazard_spawn = null

func test_ensure_chunk_spawn_signal_connected_is_idempotent() -> void:
	var runtime: RunGeneratedSpawnHookupRuntimeScript = RunGeneratedSpawnHookupRuntimeScript.new()
	var coordinator: GeneratedChunkCoordinatorScript = GeneratedChunkCoordinatorScript.new()
	var emitted_chunk: Node2D = Node2D.new()
	add_child_autofree(coordinator)
	add_child_autofree(emitted_chunk)

	runtime.ensure_chunk_spawn_signal_connected(coordinator, _record_generated_chunk_spawned)
	runtime.ensure_chunk_spawn_signal_connected(coordinator, _record_generated_chunk_spawned)
	coordinator.chunk_spawned.emit(emitted_chunk)

	assert_eq(_recorded_chunk_spawn_count, 1)

func test_connect_generated_chunk_wires_pickups_and_hazards_once() -> void:
	var runtime: RunGeneratedSpawnHookupRuntimeScript = RunGeneratedSpawnHookupRuntimeScript.new()
	var chunk_node: Node2D = Node2D.new()
	var pickup_root: Node = Node.new()
	var hazard_root: Node = Node.new()
	var pickup_spawn: GeneratedCoinPickupSpawnAdapterScript = GeneratedCoinPickupSpawnAdapterScript.new()
	var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
	var body: Node2D = Node2D.new()
	add_child_autofree(chunk_node)
	add_child_autofree(body)

	chunk_node.name = &"GeneratedChunkHarness"
	pickup_root.name = &"Pickups"
	hazard_root.name = &"Hazards"
	chunk_node.add_child(pickup_root)
	chunk_node.add_child(hazard_root)
	pickup_spawn.configure(&"pickup_01", Vector2(32.0, 48.0), 3)
	hazard_spawn.configure_hazard(
		&"hazard_01",
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER,
		Vector2(64.0, 96.0),
		Vector2.ZERO,
		preload("res://resources/config/hazard_presentation_catalog.tres").get_required_definition(GeneratedHazardKindScript.Value.SPIKE_CLUSTER)
	)
	pickup_root.add_child(pickup_spawn)
	hazard_root.add_child(hazard_spawn)

	runtime.connect_generated_chunk(chunk_node, _record_generated_coin_pickup, _record_generated_hazard_triggered)
	runtime.connect_generated_chunk(chunk_node, _record_generated_coin_pickup, _record_generated_hazard_triggered)
	pickup_spawn.collected.emit(pickup_spawn.socket_id, pickup_spawn.coin_amount, body)
	hazard_spawn.triggered.emit(body)

	assert_eq(_recorded_coin_socket_id, &"pickup_01")
	assert_eq(_recorded_coin_amount, 3)
	assert_same(_recorded_coin_body, body)
	assert_same(_recorded_hazard_body, body)
	assert_same(_recorded_hazard_spawn, hazard_spawn)

func _record_generated_chunk_spawned(_chunk_node: Node2D) -> void:
	_recorded_chunk_spawn_count += 1

func _record_generated_coin_pickup(socket_id: StringName, coin_amount: int, body: Node) -> void:
	_recorded_coin_socket_id = socket_id
	_recorded_coin_amount = coin_amount
	_recorded_coin_body = body

func _record_generated_hazard_triggered(body: Node, hazard_spawn: GeneratedHazardSpawnAdapterScript) -> void:
	_recorded_hazard_body = body
	_recorded_hazard_spawn = hazard_spawn
