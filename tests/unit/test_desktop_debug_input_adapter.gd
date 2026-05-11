extends GutTest

const DesktopDebugInputAdapterScript = preload("res://src/gameplay/player/desktop_debug_input_adapter.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")

func test_left_grip_emits_press_once_and_release_when_button_is_lifted() -> void:
    var adapter := DesktopDebugInputAdapterScript.new()
    var first_frame := adapter.create_input_frame(true, false)
    var held_frame := adapter.create_input_frame(true, false)
    var released_frame := adapter.create_input_frame(false, false)
    var first_grip_intent: Object = first_frame.grip_intents[0]
    var release_intent: Object = released_frame.release_intents[0]
    var first_hand_side: int = first_grip_intent.get("hand_side")
    var released_hand_side: int = release_intent.get("hand_side")

    assert_eq(first_frame.grip_intents.size(), 1)
    assert_eq(first_hand_side, HandSideScript.Value.LEFT)
    assert_eq(held_frame.grip_intents.size(), 0)
    assert_eq(held_frame.release_intents.size(), 0)
    assert_eq(released_frame.release_intents.size(), 1)
    assert_eq(released_hand_side, HandSideScript.Value.LEFT)

func test_dual_grip_buttons_emit_both_hand_intents() -> void:
    var adapter := DesktopDebugInputAdapterScript.new()
    var input_frame := adapter.create_input_frame(true, true)
    var left_grip_intent: Object = input_frame.grip_intents[0]
    var right_grip_intent: Object = input_frame.grip_intents[1]
    var left_hand_side: int = left_grip_intent.get("hand_side")
    var right_hand_side: int = right_grip_intent.get("hand_side")

    assert_eq(input_frame.grip_intents.size(), 2)
    assert_eq(left_hand_side, HandSideScript.Value.LEFT)
    assert_eq(right_hand_side, HandSideScript.Value.RIGHT)

func test_non_zero_aim_vector_emits_aim_intent() -> void:
    var adapter := DesktopDebugInputAdapterScript.new()
    var input_frame := adapter.create_input_frame(false, false, Vector2.LEFT)
    var aim_intent: Object = input_frame.aim_intent
    var aim_vector: Vector2 = aim_intent.get("aim_vector")

    assert_true(input_frame.has_aim_intent())
    assert_eq(aim_vector, Vector2.LEFT)

func test_debug_reset_emits_once_per_press_edge() -> void:
    var adapter := DesktopDebugInputAdapterScript.new()
    var first_frame := adapter.create_input_frame(false, false, Vector2.ZERO, true)
    var held_frame := adapter.create_input_frame(false, false, Vector2.ZERO, true)
    var released_frame := adapter.create_input_frame(false, false, Vector2.ZERO, false)
    var second_press_frame := adapter.create_input_frame(false, false, Vector2.ZERO, true)

    assert_true(first_frame.has_debug_reset_intent())
    assert_false(held_frame.has_debug_reset_intent())
    assert_false(released_frame.has_debug_reset_intent())
    assert_true(second_press_frame.has_debug_reset_intent())

func test_reset_clears_held_debug_state() -> void:
    var adapter := DesktopDebugInputAdapterScript.new()
    var _initial_frame := adapter.create_input_frame(false, false, Vector2.ZERO, true)

    adapter.reset()

    var reset_frame := adapter.create_input_frame(false, false, Vector2.ZERO, true)

    assert_true(reset_frame.has_debug_reset_intent())