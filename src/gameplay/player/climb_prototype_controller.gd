class_name ClimbPrototypeController
extends RefCounted

const AimInputIntentScript = preload("res://src/gameplay/player/aim_input_intent.gd")
const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const HandholdTargetScript = preload("res://src/gameplay/player/handhold_target.gd")
const PlayerInputFrameScript = preload("res://src/gameplay/player/player_input_frame.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")

var _tuning: ClimbPrototypeTuningScript
var _stamina: StaminaRuntimeScript
var _attachments: HandAttachmentStateScript = HandAttachmentStateScript.new()
var _last_drain_multiplier: float = 1.0

func _init(tuning: Resource, stamina: RefCounted) -> void:
    Validation.require_condition(tuning != null, "ClimbPrototypeController requires climb prototype tuning.")
    Validation.require_condition(tuning is ClimbPrototypeTuningScript, "ClimbPrototypeController requires climb prototype tuning implementation.")
    Validation.require_condition(stamina != null, "ClimbPrototypeController requires stamina runtime.")
    Validation.require_condition(stamina is StaminaRuntimeScript, "ClimbPrototypeController requires stamina runtime implementation.")

    _tuning = tuning
    _stamina = stamina
    _tuning.assert_valid()

func get_attachment_state() -> HandAttachmentStateScript:
    return _attachments

func get_climb_impulse(aim_vector: Vector2) -> Vector2:
    var normalized_aim: Vector2 = Vector2.UP

    if aim_vector != Vector2.ZERO:
        normalized_aim = aim_vector.normalized()

    var biased_direction: Vector2 = normalized_aim.lerp(Vector2.UP, _tuning.upward_impulse_bias).normalized()
    return biased_direction * _tuning.climb_impulse_pixels_per_second

func apply_input_frame(
    input_frame: RefCounted,
    left_target: RefCounted,
    right_target: RefCounted,
    delta_seconds: float
) -> ClimbPrototypeFrameResultScript:
    Validation.require_condition(input_frame != null, "ClimbPrototypeController requires an input frame.")
    Validation.require_condition(input_frame is PlayerInputFrameScript, "ClimbPrototypeController requires a PlayerInputFrame.")
    Validation.require_condition(delta_seconds >= 0.0, "ClimbPrototypeController delta seconds cannot be negative.")

    var typed_input_frame: PlayerInputFrameScript = input_frame
    typed_input_frame.assert_valid()
    var had_attachment_before_input: bool = _attachments.get_attached_hand_count() > 0

    _apply_release_intents(typed_input_frame)
    _apply_grip_intents(typed_input_frame, left_target, right_target)

    var impulse: Vector2 = Vector2.ZERO
    if typed_input_frame.has_aim_intent() and (had_attachment_before_input or _attachments.get_attached_hand_count() > 0):
        var aim_intent: AimInputIntentScript = typed_input_frame.aim_intent
        impulse = get_climb_impulse(aim_intent.aim_vector)

    var depleted_now: bool = _stamina.advance(_attachments.get_attached_hand_count(), delta_seconds, _last_drain_multiplier)
    if depleted_now:
        _attachments.release_all()

    return ClimbPrototypeFrameResultScript.new(impulse, depleted_now, _attachments.get_attached_hand_count())

func reset() -> void:
    _attachments.release_all()
    _stamina.restore_full()
    _last_drain_multiplier = 1.0

func _apply_release_intents(input_frame: PlayerInputFrameScript) -> void:
    for release_intent in input_frame.release_intents:
        var typed_release_intent: Object = release_intent
        var hand_side: int = typed_release_intent.get("hand_side")

        if _attachments.is_attached(hand_side):
            _attachments.release(hand_side)

    _refresh_drain_multiplier()

func _apply_grip_intents(input_frame: PlayerInputFrameScript, left_target: RefCounted, right_target: RefCounted) -> void:
    for grip_intent in input_frame.grip_intents:
        var typed_grip_intent: Object = grip_intent
        var hand_side: int = typed_grip_intent.get("hand_side")
        var target: RefCounted = _target_for_hand(hand_side, left_target, right_target)

        if target == null:
            continue

        Validation.require_condition(target is HandholdTargetScript, "ClimbPrototypeController requires typed handhold targets.")
        var typed_target: HandholdTargetScript = target
        typed_target.assert_valid()

        if not _attachments.is_attached(hand_side):
            _attachments.attach(hand_side, typed_target.hold_id, typed_target.attach_position)

    _refresh_drain_multiplier()

func _target_for_hand(hand_side: int, left_target: RefCounted, right_target: RefCounted) -> RefCounted:
    HandSideScript.assert_valid(hand_side)

    if hand_side == HandSideScript.Value.LEFT:
        return left_target

    return right_target

func _refresh_drain_multiplier() -> void:
    _last_drain_multiplier = 1.0
