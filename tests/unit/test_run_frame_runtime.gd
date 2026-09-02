extends GutTest

const RunEndReasonScript = preload("res://src/core/run_end_reason.gd")
const RunFrameRuntimeScript = preload("res://src/gameplay/run/run_frame_runtime.gd")
const RunSessionScript = preload("res://src/gameplay/run/run_session.gd")
const RunStateScript = preload("res://src/gameplay/run/run_state.gd")

func test_generated_chunk_sync_ignores_non_finite_height_after_run_ends() -> void:
	var runtime: RunFrameRuntimeScript = RunFrameRuntimeScript.new()
	var run_session: RunSessionScript = RunSessionScript.new()
	run_session.start_run()
	run_session.end_run(RunEndReasonScript.Value.CHASER_CONTACT)

	runtime.sync_generated_chunks(null, null, run_session, NAN, true)

	assert_eq(run_session.get_state(), RunStateScript.Value.ENDED)
