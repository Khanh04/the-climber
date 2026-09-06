extends GutTest

const ChaserFeedbackSnapshotScript = preload("res://src/gameplay/chaser/chaser_feedback_snapshot.gd")
const ChaserPacingModelScript = preload("res://src/gameplay/chaser/chaser_pacing_model.gd")
const ChaserTuningScript = preload("res://resources/config/chaser_tuning.gd")

func test_progress_thresholds_follow_documented_chaser_contract() -> void:
    var tuning := ChaserTuningScript.new()

    assert_eq(ChaserPacingModelScript.classify_progress(1.9, tuning), ChaserPacingModelScript.PaceState.CAMPING)
    assert_eq(ChaserPacingModelScript.classify_progress(2.0, tuning), ChaserPacingModelScript.PaceState.NEUTRAL)
    assert_eq(ChaserPacingModelScript.classify_progress(8.0, tuning), ChaserPacingModelScript.PaceState.NEUTRAL)
    assert_eq(ChaserPacingModelScript.classify_progress(8.1, tuning), ChaserPacingModelScript.PaceState.RAPID_CLIMB)

func test_rise_speed_applies_pacing_modifiers_and_clamps_to_bounds() -> void:
    var tuning := ChaserTuningScript.new()
    tuning.base_rise_speed_meters_per_second = 3.0
    tuning.camping_speed_bonus_meters_per_second = 3.0
    tuning.rapid_climb_slowdown_meters_per_second = 2.0
    tuning.min_rise_speed_meters_per_second = 1.5
    tuning.max_rise_speed_meters_per_second = 5.0

    assert_eq(ChaserPacingModelScript.calculate_rise_speed_meters_per_second(0.5, tuning), 5.0)
    assert_eq(ChaserPacingModelScript.calculate_rise_speed_meters_per_second(4.0, tuning), 3.0)
    assert_eq(ChaserPacingModelScript.calculate_rise_speed_meters_per_second(9.0, tuning), 1.5)

func test_speed_intensity_ratio_tracks_clamped_rise_speed() -> void:
    var tuning := ChaserTuningScript.new()
    tuning.base_rise_speed_meters_per_second = 2.75
    tuning.camping_speed_bonus_meters_per_second = 3.0
    tuning.rapid_climb_slowdown_meters_per_second = 2.25
    tuning.min_rise_speed_meters_per_second = 0.5
    tuning.max_rise_speed_meters_per_second = 5.0

    assert_eq(ChaserPacingModelScript.calculate_speed_intensity_ratio(0.5, tuning), 1.0)
    assert_eq(ChaserPacingModelScript.calculate_speed_intensity_ratio(4.0, tuning), 0.5)
    assert_eq(ChaserPacingModelScript.calculate_speed_intensity_ratio(9.0, tuning), 0.0)

func test_rise_speed_increases_with_altitude_at_a_fixed_pace() -> void:
    var tuning := ChaserTuningScript.new()
    var neutral_progress: float = (tuning.camping_progress_meters + tuning.rapid_progress_meters) * 0.5

    var low_altitude_speed: float = ChaserPacingModelScript.calculate_rise_speed_meters_per_second(neutral_progress, tuning, tuning.altitude_rise_speed_onset_meters)
    var mid_altitude_speed: float = ChaserPacingModelScript.calculate_rise_speed_meters_per_second(neutral_progress, tuning, 300.0)
    var high_altitude_speed: float = ChaserPacingModelScript.calculate_rise_speed_meters_per_second(neutral_progress, tuning, 800.0)

    assert_almost_eq(low_altitude_speed, tuning.base_rise_speed_meters_per_second, 0.0001)
    assert_gt(mid_altitude_speed, low_altitude_speed)
    assert_gt(high_altitude_speed, mid_altitude_speed)

func test_camping_deterrent_still_applies_near_the_ground() -> void:
    var tuning := ChaserTuningScript.new()
    var camping_progress: float = tuning.camping_progress_meters - 0.1
    var neutral_progress: float = tuning.camping_progress_meters + 0.1

    var camping_speed: float = ChaserPacingModelScript.calculate_rise_speed_meters_per_second(camping_progress, tuning, 10.0)
    var neutral_speed: float = ChaserPacingModelScript.calculate_rise_speed_meters_per_second(neutral_progress, tuning, 10.0)

    assert_gt(camping_speed, neutral_speed)

func test_camping_stall_up_high_no_longer_outpaces_steady_climbing() -> void:
    var tuning := ChaserTuningScript.new()
    var camping_progress: float = tuning.camping_progress_meters - 0.1
    var steady_progress: float = tuning.camping_progress_meters + 0.1

    var stalled_speed: float = ChaserPacingModelScript.calculate_rise_speed_meters_per_second(camping_progress, tuning, 900.0)
    var steady_speed: float = ChaserPacingModelScript.calculate_rise_speed_meters_per_second(steady_progress, tuning, 900.0)

    assert_almost_eq(stalled_speed, steady_speed, 0.0001)

func test_recent_progress_only_uses_samples_inside_the_active_window() -> void:
    var model := ChaserPacingModelScript.new(ChaserTuningScript.new())

    model.record_height(0.0, 2.0)
    model.record_height(1.0, 2.0)
    model.record_height(10.0, 2.0)

    assert_eq(model.get_recent_vertical_progress_meters(), 10.0)
    assert_eq(model.get_current_pace_state(), ChaserPacingModelScript.PaceState.RAPID_CLIMB)

func test_stalled_progress_is_classified_as_camping() -> void:
    var model := ChaserPacingModelScript.new(ChaserTuningScript.new())

    model.record_height(0.0, 2.0)
    model.record_height(0.5, 2.0)
    model.record_height(1.0, 2.0)

    assert_eq(model.get_recent_vertical_progress_meters(), 1.0)
    assert_eq(model.get_current_pace_state(), ChaserPacingModelScript.PaceState.CAMPING)

func test_feedback_snapshot_exposes_current_progress_speed_and_intensity() -> void:
    var tuning := ChaserTuningScript.new()
    tuning.base_rise_speed_meters_per_second = 2.75
    tuning.camping_speed_bonus_meters_per_second = 1.5
    tuning.min_rise_speed_meters_per_second = 0.5
    tuning.max_rise_speed_meters_per_second = 5.0
    var model := ChaserPacingModelScript.new(tuning)

    model.record_height(0.0, 2.0)
    model.record_height(1.0, 2.0)

    var snapshot: ChaserFeedbackSnapshotScript = model.get_current_feedback_snapshot()

    assert_eq(snapshot.pace_state, ChaserPacingModelScript.PaceState.CAMPING)
    assert_eq(snapshot.recent_vertical_progress_meters, 1.0)
    assert_eq(snapshot.rise_speed_meters_per_second, 4.25)
    assert_eq(snapshot.speed_intensity_ratio, (4.25 - 0.5) / (5.0 - 0.5))

func test_descending_samples_do_not_produce_negative_progress() -> void:
    var model := ChaserPacingModelScript.new(ChaserTuningScript.new())

    model.record_height(6.0, 2.0)
    model.record_height(3.0, 2.0)

    assert_eq(model.get_recent_vertical_progress_meters(), 3.0)

    model.record_height(1.0, 2.0)

    assert_eq(model.get_recent_vertical_progress_meters(), 0.0)
    assert_eq(model.get_current_feedback_snapshot().recent_vertical_progress_meters, 0.0)