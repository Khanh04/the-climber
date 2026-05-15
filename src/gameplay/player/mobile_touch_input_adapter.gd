class_name MobileTouchInputAdapter
extends RefCounted

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const GripInputIntentScript = preload("res://src/gameplay/player/grip_input_intent.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const MobileTouchContactScript = preload("res://src/gameplay/player/mobile_touch_contact.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const ReleaseInputIntentScript = preload("res://src/gameplay/player/release_input_intent.gd")
const TouchInputSettingsScript = preload("res://src/gameplay/player/touch_input_settings.gd")

const PULL_DRAG_DEAD_ZONE_PIXELS: float = 24.0

var _left_grip_pressed: bool = false
var _right_grip_pressed: bool = false

func create_input_frame(
    viewport_size: Vector2,
    active_touch_positions: PackedVector2Array,
    touch_settings: RefCounted
) -> PlayerInputFrameScript:
    var active_touch_contacts: Array[RefCounted] = MobileTouchContactScript.from_touch_positions(active_touch_positions)
    return create_input_frame_from_contacts(viewport_size, active_touch_contacts, touch_settings)

func create_input_frame_from_contacts(
    viewport_size: Vector2,
    active_touch_contacts: Array[RefCounted],
    touch_settings: RefCounted,
    attachment_state: RefCounted = null
) -> PlayerInputFrameScript:
    Validation.require_condition(viewport_size.x > 0.0, "MobileTouchInputAdapter requires a positive viewport width.")
    Validation.require_condition(viewport_size.y > 0.0, "MobileTouchInputAdapter requires a positive viewport height.")
    Validation.require_condition(touch_settings != null, "MobileTouchInputAdapter requires touch input settings.")
    Validation.require_condition(touch_settings is TouchInputSettingsScript, "MobileTouchInputAdapter requires TouchInputSettings.")
    Validation.require_condition(_all_touch_contacts_valid(active_touch_contacts), "MobileTouchInputAdapter requires valid touch contacts.")
    var typed_touch_settings: TouchInputSettingsScript = touch_settings as TouchInputSettingsScript
    typed_touch_settings.assert_valid()

    var left_grip_pressed_now: bool = _has_touch_in_left_zone(viewport_size, active_touch_contacts, typed_touch_settings)
    var right_grip_pressed_now: bool = _has_touch_in_right_zone(viewport_size, active_touch_contacts, typed_touch_settings)
    var grip_intents: Array = []
    var release_intents: Array = []
    var aim_intent: RefCounted = _create_pull_aim_intent(viewport_size, active_touch_contacts, typed_touch_settings, attachment_state)

    if left_grip_pressed_now and not _left_grip_pressed:
        grip_intents.append(GripInputIntentScript.new(HandSideScript.Value.LEFT))
    elif _left_grip_pressed and not left_grip_pressed_now:
        release_intents.append(ReleaseInputIntentScript.new(HandSideScript.Value.LEFT))

    if right_grip_pressed_now and not _right_grip_pressed:
        grip_intents.append(GripInputIntentScript.new(HandSideScript.Value.RIGHT))
    elif _right_grip_pressed and not right_grip_pressed_now:
        release_intents.append(ReleaseInputIntentScript.new(HandSideScript.Value.RIGHT))

    _left_grip_pressed = left_grip_pressed_now
    _right_grip_pressed = right_grip_pressed_now

    return PlayerInputFrameScript.new(grip_intents, release_intents, aim_intent)

func reset() -> void:
    _left_grip_pressed = false
    _right_grip_pressed = false

func _has_touch_in_left_zone(viewport_size: Vector2, active_touch_contacts: Array[RefCounted], touch_settings: TouchInputSettingsScript) -> bool:
    for raw_touch_contact in active_touch_contacts:
        var touch_contact: MobileTouchContactScript = _as_touch_contact(raw_touch_contact)
        if _touch_starts_in_left_zone(viewport_size, touch_contact, touch_settings):
            return true

    return false

func _has_touch_in_right_zone(viewport_size: Vector2, active_touch_contacts: Array[RefCounted], touch_settings: TouchInputSettingsScript) -> bool:
    for raw_touch_contact in active_touch_contacts:
        var touch_contact: MobileTouchContactScript = _as_touch_contact(raw_touch_contact)
        if _touch_starts_in_right_zone(viewport_size, touch_contact, touch_settings):
            return true

    return false

func _create_pull_aim_intent(
    viewport_size: Vector2,
    active_touch_contacts: Array[RefCounted],
    touch_settings: TouchInputSettingsScript,
    attachment_state: RefCounted
) -> RefCounted:
    if attachment_state == null:
        return null

    Validation.require_condition(
        attachment_state is HandAttachmentStateScript,
        "MobileTouchInputAdapter requires HandAttachmentState when attachment state is provided."
    )
    var typed_attachment_state: HandAttachmentStateScript = attachment_state as HandAttachmentStateScript
    if typed_attachment_state.get_attached_hand_count() != 1:
        return null

    var attached_hand_side: int = _get_single_attached_hand_side(typed_attachment_state)
    var touch_contact: MobileTouchContactScript = _find_touch_contact_for_hand(viewport_size, active_touch_contacts, touch_settings, attached_hand_side)
    if touch_contact == null:
        return null

    var drag_vector: Vector2 = touch_contact.get_drag_vector()
    if drag_vector.length() <= PULL_DRAG_DEAD_ZONE_PIXELS:
        return null

    return AimInputIntentScript.new(drag_vector)

func _find_touch_contact_for_hand(
    viewport_size: Vector2,
    active_touch_contacts: Array[RefCounted],
    touch_settings: TouchInputSettingsScript,
    hand_side: int
) -> MobileTouchContactScript:
    HandSideScript.assert_valid(hand_side)

    for raw_touch_contact in active_touch_contacts:
        var touch_contact: MobileTouchContactScript = _as_touch_contact(raw_touch_contact)
        var matches_hand_side: bool = false
        if hand_side == HandSideScript.Value.LEFT:
            matches_hand_side = _touch_starts_in_left_zone(viewport_size, touch_contact, touch_settings)
        else:
            matches_hand_side = _touch_starts_in_right_zone(viewport_size, touch_contact, touch_settings)

        if matches_hand_side:
            return touch_contact

    return null

func _get_single_attached_hand_side(attachment_state: HandAttachmentStateScript) -> int:
    if attachment_state.is_attached(HandSideScript.Value.LEFT):
        return HandSideScript.Value.LEFT

    return HandSideScript.Value.RIGHT

func _touch_starts_in_left_zone(viewport_size: Vector2, touch_contact: MobileTouchContactScript, touch_settings: TouchInputSettingsScript) -> bool:
    var left_boundary_x: float = _get_left_boundary_x(viewport_size, touch_settings)
    return touch_contact.start_position.x < left_boundary_x

func _touch_starts_in_right_zone(viewport_size: Vector2, touch_contact: MobileTouchContactScript, touch_settings: TouchInputSettingsScript) -> bool:
    var right_boundary_x: float = _get_right_boundary_x(viewport_size, touch_settings)
    return touch_contact.start_position.x >= right_boundary_x

func _all_touch_contacts_valid(active_touch_contacts: Array[RefCounted]) -> bool:
    for raw_touch_contact in active_touch_contacts:
        if not raw_touch_contact is MobileTouchContactScript:
            return false

        var touch_contact: MobileTouchContactScript = raw_touch_contact as MobileTouchContactScript
        if not touch_contact.is_valid():
            return false

    return true

func _as_touch_contact(raw_touch_contact: RefCounted) -> MobileTouchContactScript:
    Validation.require_condition(raw_touch_contact is MobileTouchContactScript, "MobileTouchInputAdapter requires MobileTouchContact values.")
    return raw_touch_contact as MobileTouchContactScript

func _get_left_boundary_x(viewport_size: Vector2, touch_settings: TouchInputSettingsScript) -> float:
    touch_settings.assert_valid()
    var split_x: float = viewport_size.x * touch_settings.split_ratio
    var center_dead_zone_half_width: float = viewport_size.x * touch_settings.center_dead_zone_ratio * 0.5
    return split_x - center_dead_zone_half_width

func _get_right_boundary_x(viewport_size: Vector2, touch_settings: TouchInputSettingsScript) -> float:
    touch_settings.assert_valid()
    var split_x: float = viewport_size.x * touch_settings.split_ratio
    var center_dead_zone_half_width: float = viewport_size.x * touch_settings.center_dead_zone_ratio * 0.5
    return split_x + center_dead_zone_half_width