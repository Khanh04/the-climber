class_name GeneratedPickupSocket
extends RefCounted

var socket_id: StringName
var local_position: Vector2

func _init(socket_id_value: StringName, local_position_value: Vector2) -> void:
    socket_id = socket_id_value
    local_position = local_position_value
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(not String(socket_id).is_empty(), "GeneratedPickupSocket requires a socket id.")