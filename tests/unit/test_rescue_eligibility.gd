extends GutTest

func test_falls_are_rescue_eligible_before_rescue_is_used() -> void:
    assert_true(RescueEligibility.is_rescue_eligible(RunEndReason.Value.BOTTOM_SCREEN_FALL, false))
    assert_true(RescueEligibility.is_rescue_eligible(RunEndReason.Value.STAMINA_FALL, false))
    assert_true(RescueEligibility.is_rescue_eligible(RunEndReason.Value.MISSED_GRIP_FALL, false))

func test_chaser_and_lethal_hazards_are_not_rescue_eligible() -> void:
    assert_false(RescueEligibility.is_rescue_eligible(RunEndReason.Value.CHASER_CONTACT, false))
    assert_false(RescueEligibility.is_rescue_eligible(RunEndReason.Value.LETHAL_HAZARD, false))

func test_rescue_cannot_stack_in_same_run() -> void:
    assert_false(RescueEligibility.is_rescue_eligible(RunEndReason.Value.BOTTOM_SCREEN_FALL, true))