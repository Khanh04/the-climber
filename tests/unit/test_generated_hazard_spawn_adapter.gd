extends GutTest

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")
const GeneratedHazardSpawnAdapterScript = preload("res://src/gameplay/hazards/generated_hazard_spawn_adapter.gd")

var _triggered_bodies: Array[Node] = []

func before_each() -> void:
	_triggered_bodies = []

func test_generated_hazard_spawn_adapter_triggers_on_every_body_enter() -> void:
	var hazard_spawn: GeneratedHazardSpawnAdapterScript = GeneratedHazardSpawnAdapterScript.new()
	var body: RigidBody2D = RigidBody2D.new()

	hazard_spawn.configure_hazard(
		&"repeat_hazard",
		GeneratedHazardKindScript.Value.SPIKE_CLUSTER,
		Vector2.ZERO
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