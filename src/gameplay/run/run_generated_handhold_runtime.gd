class_name RunGeneratedHandholdRuntime
extends RefCounted

const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const GeneratedHandholdAdapterScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const HandAttachmentStateScript = preload("res://src/gameplay/player/hand_attachment_state.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")

func advance_attached_lifecycle(controller: RefCounted, delta_seconds: float, resolve_generated_handhold: Callable) -> void:
	Validation.require_condition(delta_seconds >= 0.0, "RunGeneratedHandholdRuntime lifecycle advance cannot use a negative delta.")
	Validation.require_condition(resolve_generated_handhold.is_valid(), "RunGeneratedHandholdRuntime requires a generated-handhold resolver.")
	var attachment_state: HandAttachmentStateScript = _require_controller(controller).get_attachment_state()
	var left_hold_path: NodePath = NodePath()
	if attachment_state.is_attached(HandSideScript.Value.LEFT):
		left_hold_path = attachment_state.get_hold_path(HandSideScript.Value.LEFT)
		_advance_lifecycle_for_path(attachment_state, left_hold_path, delta_seconds, resolve_generated_handhold)

	if attachment_state.is_attached(HandSideScript.Value.RIGHT):
		var right_hold_path: NodePath = attachment_state.get_hold_path(HandSideScript.Value.RIGHT)
		if left_hold_path.is_empty() or right_hold_path != left_hold_path:
			_advance_lifecycle_for_path(attachment_state, right_hold_path, delta_seconds, resolve_generated_handhold)

func resolve_attachment_changes(
	controller: RefCounted,
	player: Node,
	left_was_attached: bool,
	left_previous_hold_path: NodePath,
	right_was_attached: bool,
	right_previous_hold_path: NodePath,
	resolve_generated_handhold: Callable
) -> void:
	Validation.require_condition(resolve_generated_handhold.is_valid(), "RunGeneratedHandholdRuntime requires a generated-handhold resolver.")
	var attachment_state: HandAttachmentStateScript = _require_controller(controller).get_attachment_state()
	var typed_player: PlayerCharacterScript = _require_player(player)
	_resolve_attachment_change_for_hand(
		attachment_state,
		typed_player,
		HandSideScript.Value.LEFT,
		left_was_attached,
		left_previous_hold_path,
		resolve_generated_handhold
	)
	_resolve_attachment_change_for_hand(
		attachment_state,
		typed_player,
		HandSideScript.Value.RIGHT,
		right_was_attached,
		right_previous_hold_path,
		resolve_generated_handhold
	)

func notify_hand_attached_for_path(hold_path: NodePath, resolve_generated_handhold: Callable) -> void:
	Validation.require_condition(resolve_generated_handhold.is_valid(), "RunGeneratedHandholdRuntime requires a generated-handhold resolver.")
	_notify_hand_attached(hold_path, resolve_generated_handhold)

func _advance_lifecycle_for_path(
	attachment_state: HandAttachmentStateScript,
	hold_path: NodePath,
	delta_seconds: float,
	resolve_generated_handhold: Callable
) -> void:
	var generated_handhold: GeneratedHandholdAdapterScript = _resolve_generated_handhold(hold_path, resolve_generated_handhold)
	if generated_handhold == null:
		return

	var broke_now: bool = generated_handhold.advance_attached_lifecycle(delta_seconds)
	if not broke_now:
		return

	if attachment_state.is_attached(HandSideScript.Value.LEFT) and attachment_state.get_hold_path(HandSideScript.Value.LEFT) == hold_path:
		attachment_state.release(HandSideScript.Value.LEFT)

	if attachment_state.is_attached(HandSideScript.Value.RIGHT) and attachment_state.get_hold_path(HandSideScript.Value.RIGHT) == hold_path:
		attachment_state.release(HandSideScript.Value.RIGHT)

func _resolve_attachment_change_for_hand(
	attachment_state: HandAttachmentStateScript,
	player: PlayerCharacterScript,
	hand_side: int,
	was_attached: bool,
	previous_hold_path: NodePath,
	resolve_generated_handhold: Callable
) -> void:
	HandSideScript.assert_valid(hand_side)
	var is_attached_now: bool = attachment_state.is_attached(hand_side)
	var current_hold_path: NodePath = NodePath()
	if is_attached_now:
		current_hold_path = attachment_state.get_hold_path(hand_side)

	if was_attached and (not is_attached_now or current_hold_path != previous_hold_path):
		_notify_hand_released(player, previous_hold_path, resolve_generated_handhold)

	if is_attached_now and (not was_attached or current_hold_path != previous_hold_path):
		_notify_hand_attached(current_hold_path, resolve_generated_handhold)

func _notify_hand_attached(hold_path: NodePath, resolve_generated_handhold: Callable) -> void:
	var generated_handhold: GeneratedHandholdAdapterScript = _resolve_generated_handhold(hold_path, resolve_generated_handhold)
	if generated_handhold == null:
		return

	generated_handhold.notify_hand_attached()

func _notify_hand_released(player: PlayerCharacterScript, hold_path: NodePath, resolve_generated_handhold: Callable) -> void:
	var generated_handhold: GeneratedHandholdAdapterScript = _resolve_generated_handhold(hold_path, resolve_generated_handhold)
	if generated_handhold == null or generated_handhold.is_broken():
		return

	var release_impulse_pixels: Vector2 = generated_handhold.notify_hand_released()
	if release_impulse_pixels != Vector2.ZERO:
		player.set_body_linear_velocity(player.get_body_linear_velocity() + release_impulse_pixels)

func _resolve_generated_handhold(hold_path: NodePath, resolve_generated_handhold: Callable) -> GeneratedHandholdAdapterScript:
	if hold_path.is_empty():
		return null

	var resolved_handhold: Variant = resolve_generated_handhold.call(hold_path)
	if resolved_handhold == null:
		return null

	Validation.require_condition(
		resolved_handhold is GeneratedHandholdAdapterScript,
		"RunGeneratedHandholdRuntime resolver must return GeneratedHandholdAdapter or null."
	)
	var typed_generated_handhold: GeneratedHandholdAdapterScript = resolved_handhold
	return typed_generated_handhold

func _require_controller(controller: RefCounted) -> ClimbPrototypeControllerScript:
	Validation.require_condition(controller != null, "RunGeneratedHandholdRuntime requires a climb controller.")
	Validation.require_condition(controller is ClimbPrototypeControllerScript, "RunGeneratedHandholdRuntime requires ClimbPrototypeController.")
	return controller as ClimbPrototypeControllerScript

func _require_player(player: Node) -> PlayerCharacterScript:
	Validation.require_condition(player != null, "RunGeneratedHandholdRuntime requires a player.")
	Validation.require_condition(player is PlayerCharacterScript, "RunGeneratedHandholdRuntime requires PlayerCharacter.")
	return player as PlayerCharacterScript