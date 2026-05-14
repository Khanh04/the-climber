class_name GeneratedChunkCoordinator
extends Node2D

signal chunk_spawned(chunk_node: Node2D)

var _tuning: GenerationTuning = null
var _generator: DailyChunkGenerator = null
var _builder: GeneratedChunkSceneBuilder = null
var _seed_key: String = ""
var _chunk_start_height_offset_meters: float = 0.0
var _is_configured: bool = false

func configure(
    tuning_value: GenerationTuning,
    generator_value: DailyChunkGenerator,
    builder_value: GeneratedChunkSceneBuilder,
    seed_key_value: String,
    world_origin_global_position_value: Vector2,
    chunk_start_height_offset_meters_value: float
) -> void:
    Validation.require_condition(tuning_value != null, "GeneratedChunkCoordinator requires generation tuning.")
    Validation.require_condition(generator_value != null, "GeneratedChunkCoordinator requires a chunk generator.")
    Validation.require_condition(builder_value != null, "GeneratedChunkCoordinator requires a chunk scene builder.")
    tuning_value.assert_valid()
    Validation.require_condition(
        seed_key_value.begins_with(tuning_value.generator_version + ":"),
        "GeneratedChunkCoordinator seed key must match the configured generator version."
    )
    Validation.require_condition(
        chunk_start_height_offset_meters_value >= 0.0,
        "GeneratedChunkCoordinator chunk start height offset cannot be negative."
    )

    _tuning = tuning_value
    _generator = generator_value
    _builder = builder_value
    _seed_key = seed_key_value
    _chunk_start_height_offset_meters = chunk_start_height_offset_meters_value
    global_position = world_origin_global_position_value
    _is_configured = true

func reset_chunks() -> void:
    _require_configured()
    _clear_chunks()
    sync_chunks_for_height(0.0, [])

func sync_chunks_for_height(current_height_meters: float, retained_hold_paths: Array[NodePath] = []) -> void:
    _require_configured()
    Validation.require_condition(current_height_meters >= 0.0, "GeneratedChunkCoordinator current height cannot be negative.")

    var anchor_chunk_index: int = _get_anchor_chunk_index(current_height_meters)
    var min_chunk_index: int = maxi(0, anchor_chunk_index - _tuning.chunk_keep_behind_count)
    var max_chunk_index: int = anchor_chunk_index + _tuning.chunk_spawn_ahead_count - 1

    for chunk_index in range(min_chunk_index, max_chunk_index + 1):
        _ensure_chunk(chunk_index)

    _prune_chunks_outside_window(min_chunk_index, max_chunk_index, retained_hold_paths)

func get_active_chunk_count() -> int:
    return get_child_count()

func get_chunk_node(chunk_index: int) -> Node2D:
    Validation.require_condition(chunk_index >= 0, "GeneratedChunkCoordinator chunk lookup index cannot be negative.")

    for child in get_children():
        Validation.require_condition(child is Node, "GeneratedChunkCoordinator child must be a Node.")
        var chunk_node: Node = child
        if _get_chunk_index(chunk_node) == chunk_index:
            Validation.require_condition(chunk_node is Node2D, "GeneratedChunkCoordinator chunk child must be Node2D.")
            return chunk_node as Node2D

    return null

func _require_configured() -> void:
    Validation.require_condition(_is_configured, "GeneratedChunkCoordinator must be configured before use.")

func _get_anchor_chunk_index(current_height_meters: float) -> int:
    var generated_height_meters: float = maxf(0.0, current_height_meters - _chunk_start_height_offset_meters)
    return floori(generated_height_meters / _tuning.segment_height_meters)

func _ensure_chunk(chunk_index: int) -> void:
    if get_chunk_node(chunk_index) != null:
        return

    var layout: GeneratedChunkLayout = _generator.build_chunk(_seed_key, chunk_index)
    var chunk_node: Node2D = _builder.build_chunk_node(layout)
    add_child(chunk_node)
    chunk_spawned.emit(chunk_node)

func _prune_chunks_outside_window(min_chunk_index: int, max_chunk_index: int, retained_hold_paths: Array[NodePath]) -> void:
    var existing_children: Array[Node] = get_children()

    for chunk_node in existing_children:
        var chunk_index: int = _get_chunk_index(chunk_node)
        var inside_window: bool = chunk_index >= min_chunk_index and chunk_index <= max_chunk_index
        if inside_window:
            continue

        if _chunk_contains_retained_hold_path(chunk_node, retained_hold_paths):
            continue

        remove_child(chunk_node)
        chunk_node.free()

func _chunk_contains_retained_hold_path(chunk_node: Node, retained_hold_paths: Array[NodePath]) -> bool:
    Validation.require_condition(chunk_node != null, "GeneratedChunkCoordinator retained-path check requires a chunk node.")
    var chunk_path_text: String = String(chunk_node.get_path())

    for retained_hold_path in retained_hold_paths:
        if retained_hold_path.is_empty():
            continue

        var retained_hold_path_text: String = String(retained_hold_path)
        if retained_hold_path_text == chunk_path_text or retained_hold_path_text.begins_with(chunk_path_text + "/"):
            return true

    return false

func _get_chunk_index(chunk_node: Node) -> int:
    Validation.require_condition(chunk_node.has_meta(&"chunk_index"), "GeneratedChunkCoordinator chunk node requires chunk_index metadata.")
    var raw_chunk_index: Variant = chunk_node.get_meta(&"chunk_index")
    Validation.require_condition(raw_chunk_index is int, "GeneratedChunkCoordinator chunk_index metadata must be an integer.")
    var chunk_index: int = raw_chunk_index
    return chunk_index

func _clear_chunks() -> void:
    var existing_children: Array[Node] = get_children()
    for chunk_node in existing_children:
        remove_child(chunk_node)
        chunk_node.free()