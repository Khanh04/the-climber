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
    _refresh_chunk_seam_metadata(min_chunk_index, max_chunk_index)

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
    chunk_node.set_meta(&"generated_chunk_layout", layout)
    add_child(chunk_node)
    chunk_spawned.emit(chunk_node)

func _refresh_chunk_seam_metadata(min_chunk_index: int, max_chunk_index: int) -> void:
    for chunk_index in range(min_chunk_index, max_chunk_index + 1):
        var current_chunk_node: Node2D = get_chunk_node(chunk_index)
        if current_chunk_node == null:
            continue

        var next_chunk_node: Node2D = get_chunk_node(chunk_index + 1)
        if next_chunk_node == null:
            _clear_chunk_seam_metadata(current_chunk_node)
            continue

        if _has_current_seam_metadata_for_target(current_chunk_node, chunk_index + 1):
            continue

        var current_layout: GeneratedChunkLayout = _get_required_generated_layout(current_chunk_node)
        var next_layout: GeneratedChunkLayout = _get_required_generated_layout(next_chunk_node)
        var seam_result: RefCounted = _generator.validate_chunk_seam(current_layout, next_layout)
        _apply_chunk_seam_metadata(current_chunk_node, seam_result)

func _clear_chunk_seam_metadata(chunk_node: Node2D) -> void:
    chunk_node.remove_meta(&"next_chunk_seam_is_valid")
    chunk_node.remove_meta(&"next_chunk_seam_failure_reason")
    chunk_node.remove_meta(&"next_chunk_seam_target_chunk_index")
    chunk_node.remove_meta(&"next_chunk_seam_from_hold_id")
    chunk_node.remove_meta(&"next_chunk_seam_to_hold_id")

func _has_current_seam_metadata_for_target(chunk_node: Node2D, target_chunk_index: int) -> bool:
    if not chunk_node.has_meta(&"next_chunk_seam_target_chunk_index"):
        return false

    var raw_target_chunk_index: Variant = chunk_node.get_meta(&"next_chunk_seam_target_chunk_index")
    Validation.require_condition(raw_target_chunk_index is int, "GeneratedChunkCoordinator seam target metadata must be an int.")
    var typed_target_chunk_index: int = raw_target_chunk_index
    return typed_target_chunk_index == target_chunk_index

func _get_required_generated_layout(chunk_node: Node2D) -> GeneratedChunkLayout:
    Validation.require_condition(chunk_node.has_meta(&"generated_chunk_layout"), "GeneratedChunkCoordinator chunk node requires generated layout metadata.")
    var raw_layout: Variant = chunk_node.get_meta(&"generated_chunk_layout")
    Validation.require_condition(raw_layout is GeneratedChunkLayout, "GeneratedChunkCoordinator generated layout metadata must be a GeneratedChunkLayout.")
    var layout: GeneratedChunkLayout = raw_layout
    return layout

func _apply_chunk_seam_metadata(chunk_node: Node2D, seam_result: RefCounted) -> void:
    Validation.require_condition(seam_result != null, "GeneratedChunkCoordinator seam metadata requires a validation result.")
    chunk_node.set_meta(&"next_chunk_seam_is_valid", _get_required_bool_property(seam_result, &"is_valid"))
    chunk_node.set_meta(&"next_chunk_seam_failure_reason", _get_required_string_property(seam_result, &"failure_reason"))
    chunk_node.set_meta(&"next_chunk_seam_target_chunk_index", _get_required_int_property(seam_result, &"next_chunk_index"))
    chunk_node.set_meta(&"next_chunk_seam_from_hold_id", _get_required_string_name_property(seam_result, &"from_hold_id"))
    chunk_node.set_meta(&"next_chunk_seam_to_hold_id", _get_required_string_name_property(seam_result, &"to_hold_id"))

func _get_required_bool_property(source: Object, property_name: StringName) -> bool:
    var raw_value: Variant = source.get(property_name)
    Validation.require_condition(raw_value is bool, "GeneratedChunkCoordinator expected a bool seam property.")
    var typed_value: bool = raw_value
    return typed_value

func _get_required_string_property(source: Object, property_name: StringName) -> String:
    var raw_value: Variant = source.get(property_name)
    Validation.require_condition(raw_value is String, "GeneratedChunkCoordinator expected a String seam property.")
    var typed_value: String = raw_value
    return typed_value

func _get_required_int_property(source: Object, property_name: StringName) -> int:
    var raw_value: Variant = source.get(property_name)
    Validation.require_condition(raw_value is int, "GeneratedChunkCoordinator expected an int seam property.")
    var typed_value: int = raw_value
    return typed_value

func _get_required_string_name_property(source: Object, property_name: StringName) -> StringName:
    var raw_value: Variant = source.get(property_name)
    Validation.require_condition(raw_value is StringName, "GeneratedChunkCoordinator expected a StringName seam property.")
    var typed_value: StringName = raw_value
    return typed_value

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