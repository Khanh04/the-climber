class_name CharacterSkillRuntime
extends RefCounted

## Owns the equipped character's active skill and its cooldown for the current run.

const CharacterActiveSkillScript = preload("res://src/gameplay/player/skills/character_active_skill.gd")
const CharacterSkillProfileScript = preload("res://resources/config/character_skill_profile.gd")
const ChalkUpSkillScript = preload("res://src/gameplay/player/skills/chalk_up_skill.gd")
const SkillContextScript = preload("res://src/gameplay/player/skills/skill_context.gd")
const SpartanKickSkillScript = preload("res://src/gameplay/player/skills/spartan_kick_skill.gd")
const WebSwingSkillScript = preload("res://src/gameplay/player/skills/web_swing_skill.gd")

var _profile: CharacterSkillProfileScript
var _skill: CharacterActiveSkillScript
var _cooldown_remaining_seconds: float = 0.0

func _init(profile: CharacterSkillProfileScript) -> void:
	Validation.require_condition(profile != null, "CharacterSkillRuntime requires a character skill profile.")
	profile.assert_valid()
	_profile = profile
	_skill = _build_skill(profile)

func get_profile() -> CharacterSkillProfileScript:
	return _profile

func can_activate(context: SkillContextScript) -> bool:
	return _cooldown_remaining_seconds <= 0.0 and not _skill.is_busy() and _skill.can_activate(context)

## Returns false (and spends no cooldown) when the skill has nothing to act on.
func try_activate(context: SkillContextScript) -> bool:
	if not can_activate(context):
		return false

	_skill.activate(context)
	_cooldown_remaining_seconds = _profile.cooldown_seconds
	return true

func advance(delta_seconds: float, context: SkillContextScript) -> void:
	Validation.require_condition(delta_seconds >= 0.0, "CharacterSkillRuntime delta seconds cannot be negative.")
	_cooldown_remaining_seconds = maxf(0.0, _cooldown_remaining_seconds - delta_seconds)
	_skill.advance(delta_seconds, context)

## 1.0 right after use, 0.0 when ready.
func get_cooldown_ratio() -> float:
	return _cooldown_remaining_seconds / _profile.cooldown_seconds

## Ends any effect in flight and clears the cooldown (new run or rescue).
func reset(context: SkillContextScript) -> void:
	if _skill.is_busy():
		_skill.cancel(context)
	_cooldown_remaining_seconds = 0.0

static func _build_skill(profile: CharacterSkillProfileScript) -> CharacterActiveSkillScript:
	match profile.active_kind:
		CharacterSkillProfileScript.ActiveKind.CHALK_UP:
			return ChalkUpSkillScript.new(profile.magnitude)
		CharacterSkillProfileScript.ActiveKind.SPARTAN_KICK:
			return SpartanKickSkillScript.new(profile.magnitude)
		CharacterSkillProfileScript.ActiveKind.WEB_SWING:
			return WebSwingSkillScript.new(profile.magnitude, profile.pull_seconds)
		_:
			Validation.require_condition(false, "CharacterSkillRuntime does not support this active skill kind.")
			return null
