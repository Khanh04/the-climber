extends GutTest

const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const MobileTouchInputAdapterScript = preload("res://src/gameplay/player/mobile_touch_input_adapter.gd")

func test_left_half_touch_emits_left_grip_once_and_releases_when_removed() -> void:
    var adapter := MobileTouchInputAdapterScript.new()
    var viewport_size := Vector2(100.0, 200.0)
    var left_touch_positions := PackedVector2Array([Vector2(10.0, 50.0)])
    var first_frame := adapter.create_input_frame(viewport_size, left_touch_positions)
    var held_frame := adapter.create_input_frame(viewport_size, left_touch_positions)
    var released_frame := adapter.create_input_frame(viewport_size, PackedVector2Array())
    var first_grip_intent: Object = first_frame.grip_intents[0]
    var released_intent: Object = released_frame.release_intents[0]
    var first_hand_side: int = first_grip_intent.get("hand_side")
    var released_hand_side: int = released_intent.get("hand_side")

    assert_eq(first_frame.grip_intents.size(), 1)
    assert_eq(first_frame.release_intents.size(), 0)
    assert_eq(first_hand_side, HandSideScript.Value.LEFT)

    assert_eq(held_frame.grip_intents.size(), 0)
    assert_eq(held_frame.release_intents.size(), 0)

    assert_eq(released_frame.grip_intents.size(), 0)
    assert_eq(released_frame.release_intents.size(), 1)
    assert_eq(released_hand_side, HandSideScript.Value.LEFT)

func test_dual_half_touches_emit_both_grip_intents() -> void:
    var adapter := MobileTouchInputAdapterScript.new()
    var viewport_size := Vector2(100.0, 200.0)
    var dual_touch_positions := PackedVector2Array([Vector2(10.0, 80.0), Vector2(90.0, 80.0)])
    var input_frame := adapter.create_input_frame(viewport_size, dual_touch_positions)
    var left_grip_intent: Object = input_frame.grip_intents[0]
    var right_grip_intent: Object = input_frame.grip_intents[1]
    var left_hand_side: int = left_grip_intent.get("hand_side")
    var right_hand_side: int = right_grip_intent.get("hand_side")

    assert_eq(input_frame.grip_intents.size(), 2)
    assert_eq(left_hand_side, HandSideScript.Value.LEFT)
    assert_eq(right_hand_side, HandSideScript.Value.RIGHT)
    assert_eq(input_frame.release_intents.size(), 0)

func test_non_zero_aim_vector_emits_aim_intent() -> void:
    var adapter := MobileTouchInputAdapterScript.new()
    var viewport_size := Vector2(100.0, 200.0)
    var input_frame := adapter.create_input_frame(viewport_size, PackedVector2Array(), Vector2.UP)
    var aim_intent: Object = input_frame.aim_intent
    var aim_vector: Vector2 = aim_intent.get("aim_vector")

    assert_true(input_frame.has_aim_intent())
    assert_eq(aim_vector, Vector2.UP)

func test_reset_clears_held_touch_state() -> void:
    var adapter := MobileTouchInputAdapterScript.new()
    var viewport_size := Vector2(100.0, 200.0)
    var right_touch_positions := PackedVector2Array([Vector2(75.0, 120.0)])

    var _initial_frame := adapter.create_input_frame(viewport_size, right_touch_positions)
    adapter.reset()

    var reset_frame := adapter.create_input_frame(viewport_size, right_touch_positions)
    var reset_grip_intent: Object = reset_frame.grip_intents[0]
    var reset_hand_side: int = reset_grip_intent.get("hand_side")

    assert_eq(reset_frame.grip_intents.size(), 1)
    assert_eq(reset_hand_side, HandSideScript.Value.RIGHT)