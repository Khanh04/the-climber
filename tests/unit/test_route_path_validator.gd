extends GutTest

const DailyChunkGeneratorScript: GDScript = preload("res://src/gameplay/generation/daily_chunk_generator.gd")
const GeneratedChunkLayoutScript: GDScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GeneratedChunkSeamValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_chunk_seam_validation_result.gd")
const GeneratedHandholdSocketScript: GDScript = preload("res://src/gameplay/generation/generated_handhold_socket.gd")
const GeneratedRouteValidationResultScript: GDScript = preload("res://src/gameplay/generation/generated_route_validation_result.gd")
const GenerationTuningScript: GDScript = preload("res://resources/config/generation_tuning.gd")
const HandholdLifecycleRuleScript: GDScript = preload("res://resources/config/handhold_lifecycle_rule.gd")
const HandholdMovementRuleScript: GDScript = preload("res://resources/config/handhold_movement_rule.gd")
const HandholdSurfaceProfileScript: GDScript = preload("res://resources/config/handhold_surface_profile.gd")
const HandholdTypeScript: GDScript = preload("res://src/gameplay/generation/handhold_type.gd")
const HandholdTypeDefinitionScript: GDScript = preload("res://resources/config/handhold_type_definition.gd")
const RouteRoleScript: GDScript = preload("res://src/gameplay/generation/route_role.gd")
const RoutePathValidatorScript: GDScript = preload("res://src/gameplay/generation/route_path_validator.gd")

func test_generated_opener_returns_strict_static_path() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var generator: DailyChunkGeneratorScript = DailyChunkGeneratorScript.new(tuning)
    var validator: RefCounted = _build_route_path_validator(1.20)
    var seed_key: String = DailySeedKey.from_utc_date(2026, 5, 14)
    var layout: GeneratedChunkLayoutScript = _require_chunk_layout(generator.build_chunk(seed_key, 0))

    var result: Object = _validate_layout(
        validator,
        layout,
        _default_entry_anchor_positions()
    )

    assert_true(_require_bool_property(result, &"is_valid"))
    assert_true(layout.route_exit_hold_ids.has(String(_require_string_name_property(result, &"target_hold_id"))))
    assert_eq(_require_string_property(result, &"failure_reason"), "")
    assert_gt(_require_packed_string_array_property(result, &"path_hold_ids").size(), 0)

func test_validator_rejects_layout_without_reachable_progression() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var validator: RefCounted = _build_route_path_validator(0.96)
    var handholds: Array[GeneratedHandholdSocket] = [
        _build_handhold_socket(tuning, StringName("start"), Vector2(-0.42, -0.40)),
        _build_handhold_socket(tuning, StringName("gap"), Vector2(1.20, -2.10)),
    ]
    var pickup_sockets: Array[GeneratedPickupSocket] = []
    var hazard_sockets: Array[GeneratedHazardSocket] = []
    var layout: GeneratedChunkLayoutScript = GeneratedChunkLayoutScript.new(
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.GENERATOR_VERSION,
        0,
        ChunkType.Value.LADDER,
        ChunkRouteSlot.Value.OPENER,
        ChunkDifficultyBand.Value.EASY,
        0.0,
        handholds,
        pickup_sockets,
        hazard_sockets,
        PackedStringArray(["start"]),
        PackedStringArray(["gap"])
    )

    var result: Object = _validate_layout(
        validator,
        layout,
        _default_entry_anchor_positions()
    )

    assert_false(_require_bool_property(result, &"is_valid"))
    assert_eq(
        _require_string_property(result, &"failure_reason"),
        "No path reaches a generated route exit hold within the configured move envelope."
    )
    assert_eq(_require_packed_string_array_property(result, &"path_hold_ids").size(), 0)
    assert_eq(String(_require_string_name_property(result, &"target_hold_id")), "gap")

func test_validator_returns_path_hold_sequence_for_simple_layout() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var validator: RefCounted = _build_route_path_validator(0.96)
    var handholds: Array[GeneratedHandholdSocket] = [
        _build_handhold_socket(tuning, StringName("first"), Vector2(-0.42, -0.42)),
        _build_handhold_socket(tuning, StringName("second"), Vector2(0.10, -1.08)),
        _build_handhold_socket(tuning, StringName("top"), Vector2(0.34, -1.84)),
    ]
    var pickup_sockets: Array[GeneratedPickupSocket] = []
    var hazard_sockets: Array[GeneratedHazardSocket] = []
    var layout: GeneratedChunkLayoutScript = GeneratedChunkLayoutScript.new(
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.GENERATOR_VERSION,
        0,
        ChunkType.Value.LADDER,
        ChunkRouteSlot.Value.OPENER,
        ChunkDifficultyBand.Value.EASY,
        0.0,
        handholds,
        pickup_sockets,
        hazard_sockets,
        PackedStringArray(["first"]),
        PackedStringArray(["top"])
    )

    var result: Object = _validate_layout(
        validator,
        layout,
        _default_entry_anchor_positions()
    )

    assert_true(_require_bool_property(result, &"is_valid"))
    var path_hold_ids: PackedStringArray = _require_packed_string_array_property(result, &"path_hold_ids")
    assert_eq(path_hold_ids[path_hold_ids.size() - 1], "top")
    assert_true(path_hold_ids.has("second"))

func test_validator_accepts_reachable_adjacent_chunk_seam() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var validator: RefCounted = _build_route_path_validator(1.0)
    var current_layout: GeneratedChunkLayoutScript = _build_layout_fixture(
        0,
        0.0,
        [
            _build_handhold_socket(tuning, StringName("current_mid"), Vector2(-0.10, -0.80)),
            _build_handhold_socket(tuning, StringName("current_top"), Vector2(0.05, -1.50)),
        ]
    )
    var next_layout: GeneratedChunkLayoutScript = _build_layout_fixture(
        1,
        1.8,
        [
            _build_handhold_socket(tuning, StringName("next_entry"), Vector2(0.12, -0.18)),
            _build_handhold_socket(tuning, StringName("next_upper"), Vector2(0.30, -0.92)),
        ]
    )

    var seam_result: Object = _validate_chunk_seam(validator, current_layout, next_layout)

    assert_true(_require_bool_property(seam_result, &"is_valid"))
    assert_eq(_require_string_name_property(seam_result, &"from_hold_id"), StringName("current_top"))
    assert_eq(_require_string_name_property(seam_result, &"to_hold_id"), StringName("next_entry"))

func test_validator_rejects_unreachable_adjacent_chunk_seam() -> void:
    var tuning: GenerationTuningScript = GenerationTuningScript.new()
    var validator: RefCounted = _build_route_path_validator(1.0)
    var current_layout: GeneratedChunkLayoutScript = _build_layout_fixture(
        0,
        0.0,
        [
            _build_handhold_socket(tuning, StringName("current_mid"), Vector2(-0.10, -0.80)),
            _build_handhold_socket(tuning, StringName("current_top"), Vector2(0.05, -1.50)),
        ]
    )
    var next_layout: GeneratedChunkLayoutScript = _build_layout_fixture(
        1,
        4.2,
        [
            _build_handhold_socket(tuning, StringName("next_entry"), Vector2(0.12, -0.18)),
            _build_handhold_socket(tuning, StringName("next_upper"), Vector2(0.30, -0.92)),
        ]
    )

    var seam_result: Object = _validate_chunk_seam(validator, current_layout, next_layout)

    assert_false(_require_bool_property(seam_result, &"is_valid"))
    assert_eq(
        _require_string_property(seam_result, &"failure_reason"),
        "No reachable seam connects the current chunk exit ports to the next chunk entry ports within the configured move envelope."
    )
    assert_eq(_require_string_name_property(seam_result, &"from_hold_id"), StringName("current_top"))
    assert_eq(_require_string_name_property(seam_result, &"to_hold_id"), StringName("next_entry"))

func _default_entry_anchor_positions() -> Array[Vector2]:
    return [Vector2(-0.42, -0.24), Vector2(0.42, -0.24)]

func _build_route_path_validator(max_move_distance_meters: float) -> RefCounted:
    var validator_variant: Variant = RoutePathValidatorScript.new(max_move_distance_meters)
    if not validator_variant is RefCounted:
        fail_test("RoutePathValidatorScript did not create a RefCounted instance.")
        return null

    var validator: RefCounted = validator_variant
    return validator

func _validate_layout(
    validator: RefCounted,
    layout: GeneratedChunkLayoutScript,
    entry_anchor_positions: Array[Vector2]
) -> Object:
    var result_variant: Variant = validator.call("validate_layout", layout, entry_anchor_positions)
    if not result_variant is Object:
        fail_test("RoutePathValidator returned an unexpected result type.")
        return _build_invalid_result_placeholder()

    var result_object: Object = result_variant
    return result_object

func _validate_chunk_seam(
    validator: RefCounted,
    current_layout: GeneratedChunkLayoutScript,
    next_layout: GeneratedChunkLayoutScript
) -> Object:
    var result_variant: Variant = validator.call("validate_chunk_seam", current_layout, next_layout)
    if not result_variant is Object:
        fail_test("RoutePathValidator returned an unexpected seam result type.")
        return _build_invalid_seam_result_placeholder()

    var result_object: Object = result_variant
    return result_object

func _build_invalid_result_placeholder() -> Object:
    var result_variant: Variant = GeneratedRouteValidationResultScript.new(
        false,
        "RoutePathValidator returned an unexpected result type.",
        StringName("invalid_result"),
        PackedStringArray()
    )
    if not result_variant is Object:
        fail_test("GeneratedRouteValidationResultScript did not create an Object instance.")
        return RefCounted.new()

    var result_object: Object = result_variant
    return result_object

func _build_invalid_seam_result_placeholder() -> Object:
    var result_variant: Variant = GeneratedChunkSeamValidationResultScript.new(
        false,
        "RoutePathValidator returned an unexpected seam result type.",
        0,
        1,
        StringName("invalid_from_hold"),
        StringName("invalid_to_hold")
    )
    if not result_variant is Object:
        fail_test("GeneratedChunkSeamValidationResultScript did not create an Object instance.")
        return RefCounted.new()

    var result_object: Object = result_variant
    return result_object

func _require_bool_property(result_object: Object, property_name: StringName) -> bool:
    var raw_value: Variant = result_object.get(property_name)
    if not raw_value is bool:
        fail_test("Expected %s to be a bool." % String(property_name))
        return false

    var typed_value: bool = raw_value
    return typed_value

func _require_string_property(result_object: Object, property_name: StringName) -> String:
    var raw_value: Variant = result_object.get(property_name)
    if not raw_value is String:
        fail_test("Expected %s to be a String." % String(property_name))
        return ""

    var typed_value: String = raw_value
    return typed_value

func _require_string_name_property(result_object: Object, property_name: StringName) -> StringName:
    var raw_value: Variant = result_object.get(property_name)
    if not raw_value is StringName:
        fail_test("Expected %s to be a StringName." % String(property_name))
        return StringName("")

    var typed_value: StringName = raw_value
    return typed_value

func _require_packed_string_array_property(result_object: Object, property_name: StringName) -> PackedStringArray:
    var raw_value: Variant = result_object.get(property_name)
    if not raw_value is PackedStringArray:
        fail_test("Expected %s to be a PackedStringArray." % String(property_name))
        return PackedStringArray()

    var typed_value: PackedStringArray = raw_value
    return typed_value

func _build_handhold_socket(
    tuning: GenerationTuningScript,
    hold_id: StringName,
    local_position: Vector2
) -> GeneratedHandholdSocketScript:
    var definition: HandholdTypeDefinitionScript = tuning.get_required_handhold_definition(HandholdTypeScript.Value.NORMAL)
    var surface_profile: HandholdSurfaceProfileScript = definition.surface_profile as HandholdSurfaceProfileScript
    var lifecycle_rule: HandholdLifecycleRuleScript = definition.lifecycle_rule as HandholdLifecycleRuleScript
    var movement_rule: HandholdMovementRuleScript = definition.movement_rule as HandholdMovementRuleScript
    return GeneratedHandholdSocketScript.new(
        hold_id,
        definition.definition_id,
        local_position,
        HandholdTypeScript.Value.NORMAL,
        surface_profile.stamina_drain_multiplier,
        definition.physical_size_meters,
        definition.visual_color,
        lifecycle_rule.break_after_attach_seconds,
        lifecycle_rule.breaks_on_release,
        movement_rule.release_impulse_vector,
        RouteRoleScript.Value.SETUP
    )

func _build_layout_fixture(
    chunk_index: int,
    start_height_meters: float,
    handholds: Array[GeneratedHandholdSocket],
    route_entry_hold_ids: PackedStringArray = PackedStringArray(),
    route_exit_hold_ids: PackedStringArray = PackedStringArray()
) -> GeneratedChunkLayoutScript:
    var pickup_sockets: Array[GeneratedPickupSocket] = []
    var hazard_sockets: Array[GeneratedHazardSocket] = []
    var resolved_entry_hold_ids: PackedStringArray = route_entry_hold_ids
    var resolved_exit_hold_ids: PackedStringArray = route_exit_hold_ids
    if resolved_entry_hold_ids.size() == 0:
        var _append_default_entry_result: bool = resolved_entry_hold_ids.append(String(handholds[0].hold_id))
    if resolved_exit_hold_ids.size() == 0:
        var _append_default_exit_result: bool = resolved_exit_hold_ids.append(String(handholds[handholds.size() - 1].hold_id))
    return GeneratedChunkLayoutScript.new(
        DailySeedKey.from_utc_date(2026, 5, 14),
        DailySeedKey.GENERATOR_VERSION,
        chunk_index,
        ChunkType.Value.LADDER,
        ChunkRouteSlot.Value.OPENER,
        ChunkDifficultyBand.Value.EASY,
        start_height_meters,
        handholds,
        pickup_sockets,
        hazard_sockets,
        resolved_entry_hold_ids,
        resolved_exit_hold_ids
    )

func _get_top_hold_id(layout: GeneratedChunkLayoutScript) -> String:
    var top_hold_id: String = String(layout.handholds[0].hold_id)
    var top_hold_y: float = layout.handholds[0].local_position.y

    for handhold in layout.handholds:
        if handhold.local_position.y < top_hold_y:
            top_hold_id = String(handhold.hold_id)
            top_hold_y = handhold.local_position.y

    return top_hold_id

func _require_chunk_layout(layout: RefCounted) -> GeneratedChunkLayoutScript:
    assert_true(layout is GeneratedChunkLayoutScript)
    return layout as GeneratedChunkLayoutScript