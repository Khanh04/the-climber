extends GutTest

const DailyChunkGeneratorScript = preload("res://src/gameplay/generation/daily_chunk_generator.gd")
const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const GeneratedChunkSceneBuilderScript = preload("res://src/gameplay/generation/generated_chunk_scene_builder.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")

func test_reset_chunks_spawns_initial_window() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var coordinator: GeneratedChunkCoordinatorScript = GeneratedChunkCoordinatorScript.new()
    add_child_autofree(coordinator)
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(100.0)

    coordinator.configure(
        tuning,
        generator,
        builder,
        DailySeedKey.from_utc_date(2026, 5, 14),
        Vector2(540.0, 240.0),
        12.0
    )
    coordinator.reset_chunks()

    assert_true(coordinator.global_position.is_equal_approx(Vector2(540.0, 240.0)))
    assert_eq(coordinator.get_active_chunk_count(), tuning.chunk_spawn_ahead_count)
    assert_not_null(coordinator.get_chunk_node(0))
    assert_not_null(coordinator.get_chunk_node(1))
    assert_not_null(coordinator.get_chunk_node(2))

func test_sync_chunks_prunes_old_window_but_keeps_retained_chunk_paths() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var coordinator: GeneratedChunkCoordinatorScript = GeneratedChunkCoordinatorScript.new()
    add_child_autofree(coordinator)
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var builder: GeneratedChunkSceneBuilderScript = GeneratedChunkSceneBuilderScript.new(100.0)

    coordinator.configure(
        tuning,
        generator,
        builder,
        DailySeedKey.from_utc_date(2026, 5, 14),
        Vector2(540.0, 240.0),
        12.0
    )
    coordinator.reset_chunks()

    var retained_chunk: Node2D = coordinator.get_chunk_node(0)
    var retained_handhold_container: Node = retained_chunk.get_node("Handholds")
    var retained_handhold: StaticBody2D = retained_handhold_container.get_child(0) as StaticBody2D
    var retained_hold_path: NodePath = retained_handhold.get_path()

    coordinator.sync_chunks_for_height(108.0, [retained_hold_path])

    assert_not_null(coordinator.get_chunk_node(0))
    assert_null(coordinator.get_chunk_node(1))
    assert_not_null(coordinator.get_chunk_node(3))
    assert_not_null(coordinator.get_chunk_node(6))