extends GutTest

var manager: RoundManager


func before_each() -> void:
	manager = add_child_autofree(RoundManager.new())
	manager.set_physics_process(false)
	watch_signals(EventBus)


func test_quota_matches_all_24_reference_values() -> void:
	var expected: Array = [[2, 3, 4], [2, 3, 4], [3, 4, 5], [3, 4, 5],
		[4, 5, 6], [4, 5, 6], [5, 6, 7], [5, 6, 7]]
	for domain: int in range(1, 9):
		for index: int in range(1, 4):
			assert_eq(manager.quota_for(domain, index), expected[domain - 1][index - 1])


func test_intro_countdown_and_full_five_minutes() -> void:
	assert_true(manager.begin(3, 2))
	assert_eq(manager.quota, 4)
	assert_signal_emitted_with_parameters(EventBus, "round_intro_started", [3, 2, 4])
	manager.tick(4.0)
	assert_eq(manager.state, RoundManager.State.COUNTDOWN)
	assert_eq(manager.seconds_left, 300.0)
	manager.tick(3.0)
	assert_eq(manager.state, RoundManager.State.PLAYING)
	assert_signal_emit_count(EventBus, "round_started", 1)
	manager.tick(299.5)
	assert_eq(manager.seconds_left, 0.5)
	manager.tick(1.0)
	assert_eq(manager.state, RoundManager.State.PURGE)
	assert_eq(manager.seconds_left, 0.0)
	manager.tick(1000.0)
	assert_signal_emit_count(EventBus, "purge_started", 1)


func test_large_delta_preserves_phase_remainder() -> void:
	manager.begin(1, 1)
	manager.tick(10.0)
	assert_eq(manager.seconds_left, 297.0)
	manager.tick(1000.0)
	assert_eq(manager.state, RoundManager.State.PURGE)
	assert_signal_emit_count(EventBus, "round_started", 1)
	assert_signal_emit_count(EventBus, "purge_started", 1)


func test_pause_and_invalid_deltas_do_not_advance() -> void:
	manager.begin(1, 1)
	get_tree().paused = true
	manager.tick(400.0)
	get_tree().paused = false
	for delta: float in [NAN, INF, -1.0, 0.0]:
		manager.tick(delta)
	assert_eq(manager.phase_left, 4.0)
	assert_eq(manager.state, RoundManager.State.INTRO)


func test_invalid_begin_and_reentry_leave_round_unchanged() -> void:
	for pair: Array in [[0, 1], [9, 1], [1, 0], [1, 4]]:
		assert_false(manager.begin(pair[0], pair[1]))
	assert_eq(manager.state, RoundManager.State.LOADING)
	manager.begin(1, 1)
	assert_false(manager.begin(8, 3))
	assert_eq(manager.quota, 2)
	assert_false(manager.finish({}))


func test_results_once_and_restart_with_fresh_clock() -> void:
	manager.begin(1, 1)
	manager.tick(20.0)
	var result: Dictionary = {"reason": "test", "quota": 999}
	assert_true(manager.finish(result))
	assert_eq(result.quota, 999)
	assert_eq(manager.state, RoundManager.State.RESULTS)
	assert_false(manager.finish({}))
	assert_signal_emit_count(EventBus, "round_ended", 1)
	assert_true(manager.begin(8, 3))
	assert_eq(manager.quota, 7)
	assert_eq(manager.seconds_left, 300.0)


func test_round_scene_gates_controls_and_respawn() -> void:
	var scene: Node3D = add_child_autofree(load(
		"res://levels/_test/round_sandbox.tscn").instantiate())
	var clock: RoundManager = scene.get_node("RoundManager")
	clock.set_physics_process(false)
	assert_false(scene.runner.is_physics_processing())
	clock.tick(7.0)
	assert_true(scene.runner.is_physics_processing())
	clock.tick(300.0)
	assert_false(scene.respawner.is_physics_processing())
	assert_true(scene.runner.is_physics_processing(), "Puede escapar durante Purga")
