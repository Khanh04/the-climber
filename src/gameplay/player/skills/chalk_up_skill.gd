class_name ChalkUpSkill
extends "res://src/gameplay/player/skills/character_active_skill.gd"

var _restore_ratio: float

func _init(restore_ratio: float) -> void:
	Validation.require_condition(restore_ratio > 0.0 and restore_ratio <= 1.0, "ChalkUpSkill restore ratio must be in (0, 1].")
	_restore_ratio = restore_ratio

func can_activate(context: SkillContextScript) -> bool:
	return not context.stamina.is_full()

func activate(context: SkillContextScript) -> void:
	context.stamina.restore_ratio(_restore_ratio)
