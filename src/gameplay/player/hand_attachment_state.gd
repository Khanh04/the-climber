class_name HandAttachmentState
extends RefCounted

const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")

var _left_attached: bool = false
var _right_attached: bool = false
var _left_hold_id: StringName = &""
var _right_hold_id: StringName = &""
var _left_position: Vector2 = Vector2.ZERO
var _right_position: Vector2 = Vector2.ZERO

func is_attached(hand_side: int) -> bool:
    HandSideScript.assert_valid(hand_side)

    if hand_side == HandSideScript.Value.LEFT:
        return _left_attached

    return _right_attached

func get_attached_hand_count() -> int:
    var count: int = 0

    if _left_attached:
        count += 1

    if _right_attached:
        count += 1

    return count

func get_hold_id(hand_side: int) -> StringName:
    Validation.require_condition(is_attached(hand_side), "Cannot read hold id for an unattached hand.")

    if hand_side == HandSideScript.Value.LEFT:
        return _left_hold_id

    return _right_hold_id

func get_attach_position(hand_side: int) -> Vector2:
    Validation.require_condition(is_attached(hand_side), "Cannot read attach position for an unattached hand.")

    if hand_side == HandSideScript.Value.LEFT:
        return _left_position

    return _right_position

func attach(hand_side: int, hold_id: StringName, attach_position: Vector2) -> void:
    HandSideScript.assert_valid(hand_side)
    Validation.require_condition(not String(hold_id).is_empty(), "Hand attachment requires a hold id.")
    Validation.require_condition(not is_attached(hand_side), "Cannot attach a hand that is already attached.")

    if hand_side == HandSideScript.Value.LEFT:
        _left_attached = true
        _left_hold_id = hold_id
        _left_position = attach_position
        return

    _right_attached = true
    _right_hold_id = hold_id
    _right_position = attach_position

func release(hand_side: int) -> void:
    HandSideScript.assert_valid(hand_side)
    Validation.require_condition(is_attached(hand_side), "Cannot release a hand that is not attached.")

    if hand_side == HandSideScript.Value.LEFT:
        _left_attached = false
        _left_hold_id = &""
        _left_position = Vector2.ZERO
        return

    _right_attached = false
    _right_hold_id = &""
    _right_position = Vector2.ZERO


func release_all() -> void:
    _left_attached = false
    _right_attached = false
    _left_hold_id = &""
    _right_hold_id = &""
    _left_position = Vector2.ZERO
    _right_position = Vector2.ZERO