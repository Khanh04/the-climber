class_name ReleaseInputIntent
extends RefCounted

const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")

var hand_side: int

func _init(hand_side_value: int) -> void:
    hand_side = hand_side_value
    assert_valid()

func is_valid() -> bool:
    return HandSideScript.is_valid(hand_side)

func assert_valid() -> void:
    HandSideScript.assert_valid(hand_side)