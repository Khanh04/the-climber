class_name RouteProfileTuning
extends Resource

## Easy-band baseline profile weight.
@export var easy_baseline_weight: float = 3.0
## Easy-band skill profile weight.
@export var easy_skill_weight: float = 2.0
## Easy-band recovery profile weight.
@export var easy_recovery_weight: float = 4.0
## Easy-band risk profile weight.
@export var easy_risk_weight: float = 1.0
## Easy-band pressure profile weight.
@export var easy_pressure_weight: float = 0.0
## Baseline-band baseline profile weight.
@export var baseline_baseline_weight: float = 3.0
## Baseline-band skill profile weight.
@export var baseline_skill_weight: float = 3.0
## Baseline-band recovery profile weight.
@export var baseline_recovery_weight: float = 2.0
## Baseline-band risk profile weight.
@export var baseline_risk_weight: float = 2.0
## Baseline-band pressure profile weight.
@export var baseline_pressure_weight: float = 0.25
## Challenge-band baseline profile weight.
@export var challenge_baseline_weight: float = 1.0
## Challenge-band skill profile weight.
@export var challenge_skill_weight: float = 3.0
## Challenge-band recovery profile weight.
@export var challenge_recovery_weight: float = 2.0
## Challenge-band risk profile weight.
@export var challenge_risk_weight: float = 3.0
## Challenge-band pressure profile weight.
@export var challenge_pressure_weight: float = 3.0
## Maximum consecutive repeats allowed before profile novelty pressure should intervene.
@export var max_repeat_profile_count: int = 2
## Recovery debt threshold where the scheduler should prefer recovery over pressure.
@export var recovery_debt_threshold: int = 2
## Bonus weight reserved for optional beta branches.
@export var optional_beta_bias_weight: float = 1.0
## Bonus weight reserved for novelty when recent history becomes repetitive.
@export var novelty_bonus_weight: float = 1.0

func is_valid() -> bool:
	return easy_baseline_weight >= 0.0 \
		and easy_skill_weight >= 0.0 \
		and easy_recovery_weight >= 0.0 \
		and easy_risk_weight >= 0.0 \
		and easy_pressure_weight >= 0.0 \
		and baseline_baseline_weight >= 0.0 \
		and baseline_skill_weight >= 0.0 \
		and baseline_recovery_weight >= 0.0 \
		and baseline_risk_weight >= 0.0 \
		and baseline_pressure_weight >= 0.0 \
		and challenge_baseline_weight >= 0.0 \
		and challenge_skill_weight >= 0.0 \
		and challenge_recovery_weight >= 0.0 \
		and challenge_risk_weight >= 0.0 \
		and challenge_pressure_weight >= 0.0 \
		and max_repeat_profile_count >= 1 \
		and recovery_debt_threshold >= 0 \
		and optional_beta_bias_weight >= 0.0 \
		and novelty_bonus_weight >= 0.0 \
		and _has_weight_in_each_band()

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(easy_baseline_weight >= 0.0, "Route profile easy baseline weight cannot be negative.")
	Validation.require_condition(easy_skill_weight >= 0.0, "Route profile easy skill weight cannot be negative.")
	Validation.require_condition(easy_recovery_weight >= 0.0, "Route profile easy recovery weight cannot be negative.")
	Validation.require_condition(easy_risk_weight >= 0.0, "Route profile easy risk weight cannot be negative.")
	Validation.require_condition(easy_pressure_weight >= 0.0, "Route profile easy pressure weight cannot be negative.")
	Validation.require_condition(baseline_baseline_weight >= 0.0, "Route profile baseline baseline weight cannot be negative.")
	Validation.require_condition(baseline_skill_weight >= 0.0, "Route profile baseline skill weight cannot be negative.")
	Validation.require_condition(baseline_recovery_weight >= 0.0, "Route profile baseline recovery weight cannot be negative.")
	Validation.require_condition(baseline_risk_weight >= 0.0, "Route profile baseline risk weight cannot be negative.")
	Validation.require_condition(baseline_pressure_weight >= 0.0, "Route profile baseline pressure weight cannot be negative.")
	Validation.require_condition(challenge_baseline_weight >= 0.0, "Route profile challenge baseline weight cannot be negative.")
	Validation.require_condition(challenge_skill_weight >= 0.0, "Route profile challenge skill weight cannot be negative.")
	Validation.require_condition(challenge_recovery_weight >= 0.0, "Route profile challenge recovery weight cannot be negative.")
	Validation.require_condition(challenge_risk_weight >= 0.0, "Route profile challenge risk weight cannot be negative.")
	Validation.require_condition(challenge_pressure_weight >= 0.0, "Route profile challenge pressure weight cannot be negative.")
	Validation.require_condition(max_repeat_profile_count >= 1, "Route profile max repeat count must be at least one.")
	Validation.require_condition(recovery_debt_threshold >= 0, "Route profile recovery debt threshold cannot be negative.")
	Validation.require_condition(optional_beta_bias_weight >= 0.0, "Route profile optional-beta bias weight cannot be negative.")
	Validation.require_condition(novelty_bonus_weight >= 0.0, "Route profile novelty bonus weight cannot be negative.")
	Validation.require_condition(_has_weight_in_each_band(), "Route profile tuning requires at least one selectable profile in each difficulty band.")

func _has_weight_in_each_band() -> bool:
	return _sum_easy_weights() > 0.0 \
		and _sum_baseline_weights() > 0.0 \
		and _sum_challenge_weights() > 0.0

func _sum_easy_weights() -> float:
	return easy_baseline_weight + easy_skill_weight + easy_recovery_weight + easy_risk_weight + easy_pressure_weight

func _sum_baseline_weights() -> float:
	return baseline_baseline_weight + baseline_skill_weight + baseline_recovery_weight + baseline_risk_weight + baseline_pressure_weight

func _sum_challenge_weights() -> float:
	return challenge_baseline_weight + challenge_skill_weight + challenge_recovery_weight + challenge_risk_weight + challenge_pressure_weight