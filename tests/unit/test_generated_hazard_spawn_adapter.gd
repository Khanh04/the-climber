extends GutTest

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")
const HazardPresentationCatalogResource = preload("res://resources/config/hazard_presentation_catalog.tres")

var _triggered_bodies: Array[Node] = []

func before_each() -> void:
	_triggered_bodies = []

func test_generated_hazard_spawn_adapter_triggers_on_every_body_enter() -> void:
	var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
	var body: RigidBody2D = RigidBody2D.new()

	hazard_spawn.configure_hazard(
		&"repeat_hazard",
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER,
		Vector2.ZERO,
		Vector2.ZERO,
		HazardPresentationCatalogResource.get_required_definition(GeneratedHazardKindScript.Value.SPIKE_CLUSTER)
	)
	var connect_result: int = hazard_spawn.triggered.connect(Callable(self, "_capture_triggered_body"))

	assert_eq(connect_result, OK)
	add_child_autofree(hazard_spawn)
	add_child_autofree(body)
	await get_tree().process_frame

	hazard_spawn.call("_on_body_entered", body)
	hazard_spawn.call("_on_body_entered", body)

	assert_eq(_triggered_bodies.size(), 2)
	assert_eq(_triggered_bodies[0], body)
	assert_eq(_triggered_bodies[1], body)
	assert_true(hazard_spawn.monitoring)

func _capture_triggered_body(body: Node) -> void:
	_triggered_bodies.append(body)

func test_generated_hazard_spawn_adapter_pendulum_log_moves_over_time() -> void:
	var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
	hazard_spawn.configure_hazard(&"pendulum_hazard", GeneratedHazardKindScript.Value.PENDULUM_LOG, Vector2(100.0, 100.0), Vector2.ZERO, HazardPresentationCatalogResource.get_required_definition(GeneratedHazardKindScript.Value.PENDULUM_LOG))
	add_child_autofree(hazard_spawn)
	var origin_position: Vector2 = hazard_spawn.position

	hazard_spawn.call("_physics_process", 0.5)

	assert_false(hazard_spawn.position.is_equal_approx(origin_position))

func test_generated_hazard_spawn_adapter_wandering_critter_moves_over_time() -> void:
	var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
	hazard_spawn.configure_hazard(&"critter_hazard", GeneratedHazardKindScript.Value.WANDERING_CRITTER, Vector2(50.0, 50.0), Vector2(10.0, -10.0), HazardPresentationCatalogResource.get_required_definition(GeneratedHazardKindScript.Value.WANDERING_CRITTER))
	add_child_autofree(hazard_spawn)
	var origin_position: Vector2 = hazard_spawn.position

	hazard_spawn.call("_physics_process", 0.5)

	assert_false(hazard_spawn.position.is_equal_approx(origin_position))

func test_generated_hazard_spawn_adapter_falling_rock_repeats_downward_motion() -> void:
	var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
	hazard_spawn.configure_hazard(&"falling_rock_hazard", GeneratedHazardKindScript.Value.FALLING_ROCK, Vector2(20.0, 30.0), Vector2.ZERO, HazardPresentationCatalogResource.get_required_definition(GeneratedHazardKindScript.Value.FALLING_ROCK))
	add_child_autofree(hazard_spawn)
	var origin_position: Vector2 = hazard_spawn.position

	hazard_spawn.call("_physics_process", GeneratedHazardSpawnAdapterScript.FALLING_ROCK_CYCLE_SECONDS * 0.5)

	assert_eq(hazard_spawn.position.x, origin_position.x)
	assert_gt(hazard_spawn.position.y, origin_position.y)

	hazard_spawn.call("_physics_process", GeneratedHazardSpawnAdapterScript.FALLING_ROCK_CYCLE_SECONDS * 0.5)

	assert_true(hazard_spawn.position.is_equal_approx(origin_position))

func test_generated_hazard_spawn_adapter_static_kinds_do_not_move() -> void:
	var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
	hazard_spawn.configure_hazard(&"spike_hazard", GeneratedHazardKindScript.Value.SPIKE_CLUSTER, Vector2(20.0, 20.0), Vector2.ZERO, HazardPresentationCatalogResource.get_required_definition(GeneratedHazardKindScript.Value.SPIKE_CLUSTER))
	add_child_autofree(hazard_spawn)
	var origin_position: Vector2 = hazard_spawn.position

	hazard_spawn.call("_physics_process", 0.5)

	assert_true(hazard_spawn.position.is_equal_approx(origin_position))
