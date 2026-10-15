class_name CharacterActiveSkill
extends RefCounted

## Base for a character's HUD-triggered skill. Cooldown lives in CharacterSkillRuntime.

const SkillContextScript = preload("res://src/gameplay/player/skills/skill_context.gd")

func can_activate(_context: SkillContextScript) -> bool:
	Validation.require_condition(false, "CharacterActiveSkill.can_activate must be overridden.")
	return false

func activate(_context: SkillContextScript) -> void:
	Validation.require_condition(false, "CharacterActiveSkill.activate must be overridden.")

## Called every climbing frame, before the climb controller runs.
func advance(_delta_seconds: float, _context: SkillContextScript) -> void:
	pass

## True while an effect is still playing out (blocks re-activation).
func is_busy() -> bool:
	return false

func cancel(_context: SkillContextScript) -> void:
	pass
