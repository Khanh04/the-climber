@tool
class_name CharacterSkillProfile
extends Resource

## Gameplay sidegrade a character carries: one always-on passive and one HUD-triggered active.
## See ADR 0013. Passive values scale the run's base tuning; they never replace it.

# ponytail: temporary kill switch while skills are tuned; delete with the gates that read it.
## Off: characters climb with neutral passives, no active skill, and no skill text in the store.
static var skills_enabled: bool = false

enum ActiveKind {
	CHALK_UP,
	SPARTAN_KICK,
	WEB_SWING,
}

@export var passive_name: String = ""
@export var active_name: String = ""
@export_multiline var description: String = ""

@export_group("Passive")
@export var max_stamina_multiplier: float = 1.0
@export var swing_force_multiplier: float = 1.0
## Scales knock-back from wind, drafts and critters.
@export var hazard_impulse_multiplier: float = 1.0
## Hold drain multipliers above 1.0 (greasy, slopers) are capped at 1.0.
@export var caps_hold_drain: bool = false
## With no hand attached, any hand that has a grab target grips on its own.
@export var auto_catch: bool = false

@export_group("Active")
@export var active_kind: ActiveKind = ActiveKind.CHALK_UP
@export var cooldown_seconds: float = 20.0
## CHALK_UP: stamina ratio restored (0, 1]. SPARTAN_KICK: launch speed in px/s. WEB_SWING: reach multiplier over the grab radius (> 1).
@export var magnitude: float = 0.5
## WEB_SWING only: seconds the pull toward the target lasts.
@export var pull_seconds: float = 0.3

func is_valid() -> bool:
	return not passive_name.is_empty() \
		and not active_name.is_empty() \
		and not description.is_empty() \
		and max_stamina_multiplier > 0.0 \
		and swing_force_multiplier > 0.0 \
		and hazard_impulse_multiplier > 0.0 \
		and cooldown_seconds > 0.0 \
		and pull_seconds > 0.0 \
		and _is_magnitude_valid()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(not passive_name.is_empty(), "Character skill profile requires a passive name.")
	Validation.require_condition(not active_name.is_empty(), "Character skill profile requires an active name.")
	Validation.require_condition(not description.is_empty(), "Character skill profile requires a description.")
	Validation.require_condition(max_stamina_multiplier > 0.0, "Character skill max stamina multiplier must be positive.")
	Validation.require_condition(swing_force_multiplier > 0.0, "Character skill swing force multiplier must be positive.")
	Validation.require_condition(hazard_impulse_multiplier > 0.0, "Character skill hazard impulse multiplier must be positive.")
	Validation.require_condition(cooldown_seconds > 0.0, "Character skill cooldown must be positive.")
	Validation.require_condition(pull_seconds > 0.0, "Character skill pull seconds must be positive.")
	Validation.require_condition(_is_magnitude_valid(), "Character skill magnitude is out of range for its active kind.")

func _is_magnitude_valid() -> bool:
	match active_kind:
		ActiveKind.CHALK_UP:
			return magnitude > 0.0 and magnitude <= 1.0
		ActiveKind.SPARTAN_KICK:
			return magnitude > 0.0
		ActiveKind.WEB_SWING:
			return magnitude > 1.0
		_:
			return false
