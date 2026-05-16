class_name GeneratedHandholdSocket
extends RefCounted

const HandholdTypeScript = preload("res://src/gameplay/generation/handhold_type.gd")
const RouteRoleScript = preload("res://src/gameplay/generation/route_role.gd")

var hold_id: StringName
var definition_id: StringName
var local_position: Vector2
var handhold_type: int
var route_role: int
var physical_size_meters: Vector2
var stamina_drain_multiplier: float
var visual_color: Color
var break_after_attach_seconds: float
var breaks_on_release: bool
var release_impulse_vector_pixels: Vector2

func _init(
	hold_id_value: StringName,
    definition_id_value: StringName,
	local_position_value: Vector2,
    handhold_type_value: int,
    stamina_drain_multiplier_value: float,
    physical_size_meters_value: Vector2,
    visual_color_value: Color,
    break_after_attach_seconds_value: float,
    breaks_on_release_value: bool,
    release_impulse_vector_pixels_value: Vector2,
    route_role_value: int = RouteRoleScript.Value.SETUP
) -> void:
    hold_id = hold_id_value
    definition_id = definition_id_value
    local_position = local_position_value
    handhold_type = handhold_type_value
    route_role = route_role_value
    stamina_drain_multiplier = stamina_drain_multiplier_value
    physical_size_meters = physical_size_meters_value
    visual_color = visual_color_value
    break_after_attach_seconds = break_after_attach_seconds_value
    breaks_on_release = breaks_on_release_value
    release_impulse_vector_pixels = release_impulse_vector_pixels_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(not String(hold_id).is_empty(), "GeneratedHandholdSocket requires a hold id.")
    Validation.require_condition(not String(definition_id).is_empty(), "GeneratedHandholdSocket requires a definition id.")
    HandholdTypeScript.assert_valid(handhold_type)
    RouteRoleScript.assert_valid(route_role)
    Validation.require_condition(
        physical_size_meters.x > 0.0 and physical_size_meters.y > 0.0,
        "GeneratedHandholdSocket physical size must be positive."
    )
    Validation.require_condition(stamina_drain_multiplier > 0.0, "GeneratedHandholdSocket stamina drain multiplier must be positive.")
    Validation.require_condition(
        break_after_attach_seconds >= 0.0,
        "GeneratedHandholdSocket break-after-attach seconds cannot be negative."
    )