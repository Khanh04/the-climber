class_name GeneratedHazardSocket
extends RefCounted

const GeneratedHazardKindScript = preload("res://src/gameplay/generation/generated_hazard_kind.gd")

var socket_id: StringName
var hazard_kind: int
var local_position: Vector2

func _init(socket_id_value: StringName, hazard_kind_value: int, local_position_value: Vector2) -> void:
    socket_id = socket_id_value
    hazard_kind = hazard_kind_value
    local_position = local_position_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(not String(socket_id).is_empty(), "GeneratedHazardSocket requires a socket id.")
    GeneratedHazardKindScript.assert_valid(hazard_kind)