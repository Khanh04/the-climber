extends GutTest

const RunResource = preload("res://scenes/main/run_scene.tscn")
const CONTENT: String = "UiLayer/RunEndScreen/CenterContainer/Panel/ContentMargin/Content/"

func test_run_end_displays_saved_record_and_distinct_coin_totals_without_awarding_again() -> void:
	var memory: InMemoryLocalStorageAdapter = InMemoryLocalStorageAdapter.new()
	BestScoreStorage.new(memory).record_height(128.5)
	SaveStorage.new(memory).save_snapshot(SaveSnapshot.new(246))
	var run: RunScene = RunResource.instantiate() as RunScene
	run.set_local_storage_adapter(memory)
	add_child_autofree(run)
	run.process_mode = Node.PROCESS_MODE_DISABLED
	var session: RunSession = run.get_test_adapter_for_test().get_run_session_for_test()
	session.record_height(86.4)
	session.add_run_earned_coins(12)
	session.end_run(RunEndReason.Value.CHASER_CONTACT)
	for refresh: int in range(3):
		var _result: Variant = run.call("_refresh_ui")
	assert_eq((run.get_node(CONTENT + "ScoreValue") as Label).text, "86.4 m")
	assert_eq((run.get_node(CONTENT + "BestScoreValue") as Label).text, "128.5 m")
	assert_eq((run.get_node(CONTENT + "RunCoinsValue") as Label).text, "12")
	assert_eq((run.get_node(CONTENT + "WalletCoinsValue") as Label).text, "246")
	assert_eq(run.get_test_adapter_for_test().get_wallet_for_test().get_coins(), 246)
	assert_eq(SaveStorage.new(memory).load_snapshot().wallet_coins, 246)
	assert_eq(BestScoreStorage.new(memory).get_best_height_meters(), 128.5)
	assert_false((run.get_node("UiLayer/RunHud") as Control).visible)
	assert_true((run.get_node("UiLayer/RunEndScreen") as Control).visible)
	var _restart: Variant = run.call("_request_restart")
	assert_true((run.get_node("UiLayer/RunHud") as Control).visible)
	assert_false((run.get_node("UiLayer/RunEndScreen") as Control).visible)

func test_new_record_is_saved_and_shown_on_results_before_returning_to_menu() -> void:
	var memory: InMemoryLocalStorageAdapter = InMemoryLocalStorageAdapter.new()
	BestScoreStorage.new(memory).record_height(10.0)
	var run: RunScene = RunResource.instantiate() as RunScene
	run.set_local_storage_adapter(memory)
	add_child_autofree(run)
	run.process_mode = Node.PROCESS_MODE_DISABLED
	var session: RunSession = run.get_test_adapter_for_test().get_run_session_for_test()
	session.record_height(42.7)
	session.end_run(RunEndReason.Value.CHASER_CONTACT)
	var _result: Variant = run.call("_refresh_ui")
	assert_eq((run.get_node(CONTENT + "ScoreValue") as Label).text, "42.7 m")
	assert_eq((run.get_node(CONTENT + "BestScoreValue") as Label).text, "42.7 m")
	assert_eq(BestScoreStorage.new(memory).get_best_height_meters(), 42.7)

