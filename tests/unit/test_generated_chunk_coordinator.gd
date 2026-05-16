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
    var chunk_start_height_offset_meters: float = 12.0

    coordinator.configure(
        tuning,
        generator,
        builder,
        DailySeedKey.from_utc_date(2026, 5, 14),
        Vector2(540.0, 240.0),
        chunk_start_height_offset_meters
    )
    coordinator.reset_chunks()

    var retained_chunk: Node2D = coordinator.get_chunk_node(0)
    var retained_handhold_container: Node = retained_chunk.get_node("Handholds")
    var retained_handhold: StaticBody2D = retained_handhold_container.get_child(0) as StaticBody2D
    var retained_hold_path: NodePath = retained_handhold.get_path()
    var current_height_meters: float = 108.0
    var generated_height_meters: float = maxf(0.0, current_height_meters - chunk_start_height_offset_meters)
    var anchor_chunk_index: int = floori(generated_height_meters / tuning.segment_height_meters)
    var min_chunk_index: int = maxi(0, anchor_chunk_index - tuning.chunk_keep_behind_count)
    var max_chunk_index: int = anchor_chunk_index + tuning.chunk_spawn_ahead_count - 1

    coordinator.sync_chunks_for_height(current_height_meters, [retained_hold_path])

    assert_not_null(coordinator.get_chunk_node(0))
    assert_null(coordinator.get_chunk_node(1))
    assert_not_null(coordinator.get_chunk_node(min_chunk_index))
    assert_not_null(coordinator.get_chunk_node(max_chunk_index))

func test_reset_chunks_records_next_chunk_seam_metadata() -> void:
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

    var chunk_zero: Node2D = coordinator.get_chunk_node(0)
    assert_not_null(chunk_zero)
    assert_true(chunk_zero.has_meta(&"next_chunk_seam_is_valid"))
    assert_true(chunk_zero.has_meta(&"next_chunk_seam_target_chunk_index"))
    assert_true(chunk_zero.has_meta(&"next_chunk_seam_failure_reason"))
    var next_chunk_seam_is_valid: bool = _get_bool_meta(chunk_zero, &"next_chunk_seam_is_valid")
    var next_chunk_seam_target_chunk_index: int = _get_int_meta(chunk_zero, &"next_chunk_seam_target_chunk_index")
    var next_chunk_seam_failure_reason: String = _get_string_meta(chunk_zero, &"next_chunk_seam_failure_reason")
    assert_eq(next_chunk_seam_is_valid, false)
    assert_eq(next_chunk_seam_target_chunk_index, 1)
    assert_eq(
        next_chunk_seam_failure_reason,
        "No reachable seam connects the current chunk exit ports to the next chunk entry ports within the configured move envelope."
    )

func _get_bool_meta(node: Node, key: StringName) -> bool:
    var raw_value: Variant = node.get_meta(key)
    if not raw_value is bool:
        fail_test("Expected bool metadata for %s." % String(key))
        return false

    var typed_value: bool = raw_value
    return typed_value

func _get_int_meta(node: Node, key: StringName) -> int:
    var raw_value: Variant = node.get_meta(key)
    if not raw_value is int:
        fail_test("Expected int metadata for %s." % String(key))
        return 0

    var typed_value: int = raw_value
    return typed_value

func _get_string_meta(node: Node, key: StringName) -> String:
    var raw_value: Variant = node.get_meta(key)
    if not raw_value is String:
        fail_test("Expected string metadata for %s." % String(key))
        return ""

    var typed_value: String = raw_value
    return typed_value