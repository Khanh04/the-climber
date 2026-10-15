extends GutTest

const CharacterSkillProfileScript = preload("res://resources/config/character_skill_profile.gd")
const CharacterSkillRuntimeScript = preload("res://src/gameplay/player/skills/character_skill_runtime.gd")
const ClimbPrototypeControllerScript = preload("res://src/gameplay/player/climb_prototype_controller.gd")
const ClimbPrototypeTuningScript = preload("res://resources/config/climb_prototype_tuning.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const SkillContextScript = preload("res://src/gameplay/player/skills/skill_context.gd")
const SpartanKickSkillScript = preload("res://src/gameplay/player/skills/spartan_kick_skill.gd")
const StaminaRuntimeScript = preload("res://src/gameplay/player/stamina_runtime.gd")
const StaminaTuningScript = preload("res://resources/config/stamina_tuning.gd")
const WebSwingSkillScript = preload("res://src/gameplay/player/skills/web_swing_skill.gd")

const GRAB_RADIUS: float = 96.0

var _player: PlayerCharacterScript
var _stamina: StaminaRuntimeScript
var _controller: ClimbPrototypeControllerScript

func before_each() -> void:
	var player_node: Node = (load("res://scenes/player/player_character.tscn") as PackedScene).instantiate()
	_player = player_node as PlayerCharacterScript
	add_child_autofree(_player)
	await get_tree().process_frame
	_stamina = StaminaRuntimeScript.new(StaminaTuningScript.new())
	_controller = ClimbPrototypeControllerScript.new(ClimbPrototypeTuningScript.new(), _stamina)

func test_chalk_up_is_unavailable_at_full_stamina_and_restores_when_drained() -> void:
	var runtime: CharacterSkillRuntimeScript = CharacterSkillRuntimeScript.new(_profile(CharacterSkillProfileScript.ActiveKind.CHALK_UP, 0.5))
	var context: SkillContextScript = _context(Vector2.ZERO, [])
	assert_false(runtime.try_activate(context), "Nothing to restore at full stamina.")
	assert_eq(runtime.get_cooldown_ratio(), 0.0)

	var _depleted: bool = _stamina.advance(1, _stamina.get_max_stamina_seconds() * 0.75)
	assert_true(runtime.try_activate(context))

	assert_almost_eq(_stamina.get_current_stamina_seconds(), _stamina.get_max_stamina_seconds() * 0.75, 0.001)
	assert_eq(runtime.get_cooldown_ratio(), 1.0)

func test_cooldown_blocks_reuse_until_it_elapses_and_reset_clears_it() -> void:
	var profile: CharacterSkillProfileScript = _profile(CharacterSkillProfileScript.ActiveKind.CHALK_UP, 0.1)
	var runtime: CharacterSkillRuntimeScript = CharacterSkillRuntimeScript.new(profile)
	var context: SkillContextScript = _context(Vector2.ZERO, [])
	var _depleted: bool = _stamina.advance(1, _stamina.get_max_stamina_seconds() * 0.9)
	assert_true(runtime.try_activate(context))

	assert_false(runtime.try_activate(context), "Still cooling down.")
	runtime.advance(profile.cooldown_seconds * 0.5, context)
	assert_almost_eq(runtime.get_cooldown_ratio(), 0.5, 0.001)
	runtime.advance(profile.cooldown_seconds, context)
	assert_true(runtime.try_activate(context))

	runtime.reset(context)
	assert_eq(runtime.get_cooldown_ratio(), 0.0)

func test_spartan_kick_launches_up_and_away_from_the_push_off_hold() -> void:
	var to_the_right: Vector2 = SpartanKickSkillScript.launch_velocity(Vector2(0.0, 0.0), Vector2(50.0, 40.0), 900.0)
	assert_gt(to_the_right.x, 0.0)
	assert_lt(to_the_right.y, 0.0)
	assert_almost_eq(to_the_right.length(), 900.0, 0.01)

	var straight_up: Vector2 = SpartanKickSkillScript.launch_velocity(Vector2(10.0, 0.0), Vector2(10.0, 40.0), 900.0)
	assert_eq(straight_up.x, 0.0)
	assert_lt(straight_up.y, 0.0)

func test_spartan_kick_needs_a_hand_on_a_hold_and_releases_all_hands() -> void:
	var runtime: CharacterSkillRuntimeScript = CharacterSkillRuntimeScript.new(_profile(CharacterSkillProfileScript.ActiveKind.SPARTAN_KICK, 900.0))
	var context: SkillContextScript = _context(Vector2.ZERO, [])
	assert_false(runtime.try_activate(context), "Cannot kick off thin air.")

	_controller.get_attachment_state().attach(HandSideScript.Value.LEFT, &"hold", _player.get_body_global_position() + Vector2(-30.0, -60.0), NodePath("hold"))
	assert_true(runtime.try_activate(context))

	assert_eq(_controller.get_attachment_state().get_attached_hand_count(), 0)
	assert_lt(_player.get_body_linear_velocity().y, 0.0)
	assert_gt(_player.get_body_linear_velocity().x, 0.0)

func test_web_swing_targets_the_nearest_far_hold_inside_the_aim_cone() -> void:
	var origin: Vector2 = _context(Vector2.ZERO, []).get_hand_midpoint()
	var within_grab_reach: Node2D = _hold(origin + Vector2(0.0, -GRAB_RADIUS * 0.5))
	var far_up: Node2D = _hold(origin + Vector2(10.0, -GRAB_RADIUS * 1.6))
	var farther_up: Node2D = _hold(origin + Vector2(0.0, -GRAB_RADIUS * 1.9))
	var off_to_the_side: Node2D = _hold(origin + Vector2(GRAB_RADIUS * 1.5, 0.0))
	var out_of_web_reach: Node2D = _hold(origin + Vector2(0.0, -GRAB_RADIUS * 3.0))
	var skill: WebSwingSkillScript = WebSwingSkillScript.new(2.0, 0.3)

	var target: Node2D = skill.find_target(_context(Vector2.ZERO, [within_grab_reach, far_up, farther_up, off_to_the_side, out_of_web_reach]))
	assert_eq(target, far_up, "Not aiming defaults to straight up.")

	target = skill.find_target(_context(Vector2.RIGHT, [within_grab_reach, far_up, off_to_the_side]))
	assert_eq(target, off_to_the_side)

func test_web_swing_without_a_target_spends_no_cooldown() -> void:
	var runtime: CharacterSkillRuntimeScript = CharacterSkillRuntimeScript.new(_profile(CharacterSkillProfileScript.ActiveKind.WEB_SWING, 2.0))
	var context: SkillContextScript = _context(Vector2.ZERO, [])

	assert_false(runtime.can_activate(context))
	assert_false(runtime.try_activate(context))
	assert_eq(runtime.get_cooldown_ratio(), 0.0)

func test_web_swing_pulls_toward_the_target_and_lets_go_after_the_pull() -> void:
	var origin: Vector2 = _context(Vector2.ZERO, []).get_hand_midpoint()
	var target: Node2D = _hold(origin + Vector2(0.0, -GRAB_RADIUS * 1.8))
	var skill: WebSwingSkillScript = WebSwingSkillScript.new(2.0, 0.3)
	var context: SkillContextScript = _context(Vector2.ZERO, [target])
	_controller.get_attachment_state().attach(HandSideScript.Value.LEFT, &"start", origin, NodePath("start"))

	skill.activate(context)
	assert_true(skill.is_busy())
	assert_eq(_controller.get_attachment_state().get_attached_hand_count(), 0)

	skill.advance(0.016, context)
	assert_lt(_player.get_body_linear_velocity().y, 0.0, "Pulled up toward the target.")

	skill.advance(1.0, context)
	assert_false(skill.is_busy(), "The web lets go once the pull and catch grace are over.")

func _profile(kind: CharacterSkillProfileScript.ActiveKind, magnitude: float) -> CharacterSkillProfileScript:
	var profile: CharacterSkillProfileScript = CharacterSkillProfileScript.new()
	profile.passive_name = "Passive"
	profile.active_name = "Active"
	profile.description = "Test kit."
	profile.active_kind = kind
	profile.magnitude = magnitude
	profile.cooldown_seconds = 10.0
	profile.assert_valid()
	return profile

func _context(aim_vector: Vector2, handholds: Array[Node2D]) -> SkillContextScript:
	return SkillContextScript.new(_controller, _player, _stamina, aim_vector, handholds, GRAB_RADIUS)

func _hold(global_position_value: Vector2) -> Node2D:
	var hold: Node2D = Node2D.new()
	add_child_autofree(hold)
	hold.global_position = global_position_value
	return hold
