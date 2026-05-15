class_name MobileTouchContact
extends RefCounted

const SELF_SCRIPT: GDScript = preload("res://src/gameplay/player/mobile_touch_contact.gd")

var index: int
var start_position: Vector2
var current_position: Vector2

func _init(index_value: int, start_position_value: Vector2, current_position_value: Vector2 = Vector2.INF) -> void:
	index = index_value
	start_position = start_position_value
	current_position = current_position_value
	if current_position == Vector2.INF:
		current_position = start_position
	assert_valid()

static func from_touch_positions(active_touch_positions: PackedVector2Array) -> Array[RefCounted]:
	var touch_contacts: Array[RefCounted] = []
	for touch_index in range(active_touch_positions.size()):
		var touch_position: Vector2 = active_touch_positions[touch_index]
		touch_contacts.append(SELF_SCRIPT.new(touch_index, touch_position, touch_position))

	return touch_contacts

func update_current_position(current_position_value: Vector2) -> void:
	current_position = current_position_value

func get_drag_vector() -> Vector2:
	return current_position - start_position

func is_valid() -> bool:
	return index >= 0

func assert_valid() -> void:
	Validation.require_condition(index >= 0, "Mobile touch contact index must be non-negative.")