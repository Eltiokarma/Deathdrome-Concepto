extends GutTest

var scene: Node3D
var score: RoundScore
var player: Runner
var target: Runner


func before_each() -> void:
	scene = add_child_autofree(load("res://levels/_test/round_sandbox.tscn").instantiate())
	score = scene.score
	player = scene.runner
	target = scene.target
	scene.round_manager.set_physics_process(false)
	scene.round_manager.tick(7.0)
	player.set_physics_process(false)
	target.set_physics_process(false)
	scene.respawner.set_physics_process(false)
	scene.portal.set_physics_process(false)
	watch_signals(EventBus)


func _kill(weapon: StringName = &"laser", attributed: bool = true) -> void:
	var info := DamageInfo.new()
	info.source = player if attributed else null
	info.type = Enums.DamageType.PURGE
	info.weapon_id = weapon
	target.health.apply(info)


func _revive() -> void:
	target.reset_at(Vector3(-17, 0.1, 0))


func test_first_blood_and_barrier_bonus_are_once_per_life() -> void:
	_kill(&"barrier")
	assert_eq(score.points_for(player), 1550)
	EventBus.runner_destroyed.emit(target, player, &"barrier")
	assert_eq(score.points_for(player), 1550)
	_revive()
	_kill(&"barrier")
	assert_eq(score.points_for(player), 2800)
	assert_signal_emit_count(EventBus, "score_changed", 2)


func test_unattributed_penalty_does_not_claim_first_blood() -> void:
	_kill(&"environment", false)
	assert_eq(score.points_for(target), -250)
	_revive()
	_kill(&"tower")
	assert_eq(score.points_for(player), 1550)


func test_mercy_is_once_and_does_not_change_quota() -> void:
	_kill()
	EventBus.mercy_kill.emit(player, target)
	EventBus.mercy_kill.emit(player, target)
	assert_eq(score.points_for(player), 1800)
	assert_eq(scene.progress.kills_for(player), 1)
	_revive()
	EventBus.mercy_kill.emit(player, target)
	assert_eq(score.points_for(player), 1800)


func test_escape_uses_whole_entry_seconds_and_awards_before_results() -> void:
	_kill()
	_revive()
	_kill()
	scene.round_manager.tick(100.25)
	scene.portal._on_entered(player)
	scene.round_manager.tick(2.0)
	scene.portal.tick(3.0)
	assert_eq(score.points_for(player), 6290) # 2300 + 2000 + 199*10.
	assert_eq(scene.round_manager.state, RoundManager.State.RESULTS)
	assert_string_contains(scene.get_node("UI/ScoreStatus").text, "6290")
	EventBus.runner_escaped.emit(player, 199.75)
	assert_eq(score.points_for(player), 6290)


func test_purge_bonus_uses_entry_time_not_completion_phase() -> void:
	_kill()
	_revive()
	_kill()
	scene.round_manager.tick(299.5)
	scene.portal._on_entered(player)
	scene.round_manager.tick(0.5)
	scene.portal.tick(3.0)
	assert_eq(score.points_for(player), 4300, "Entrada antes de Purga: sin bonus de Purga")


func test_zero_clock_escape_gets_purge_bonus() -> void:
	_kill()
	_revive()
	_kill()
	scene.round_manager.tick(300.0)
	scene.portal._on_entered(player)
	scene.portal.tick(3.0)
	assert_eq(score.points_for(player), 5300)


func test_new_round_preserves_points_and_resets_first_blood() -> void:
	_kill()
	scene.round_manager.finish({})
	scene.round_manager.begin(2, 1)
	assert_eq(score.points_for(player), 1300)
	scene.round_manager.tick(7.0)
	_revive()
	_kill()
	assert_eq(score.points_for(player), 2600)


func test_no_reward_for_invalid_escape_or_events_outside_play() -> void:
	score._on_escaped(player, 100.0)
	assert_eq(score.points_for(player), 0)
	_kill()
	_revive()
	_kill()
	for time_left: float in [NAN, INF, -1.0, 301.0]:
		score._on_escaped(player, time_left)
	assert_eq(score.points_for(player), 2300)
	scene.round_manager.finish({})
	_revive()
	_kill()
	EventBus.mercy_kill.emit(player, target)
	assert_eq(score.points_for(player), 2300)


func test_suicide_penalty_and_first_blood_shared_by_all_participants() -> void:
	var hit := DamageInfo.new()
	hit.source = target
	hit.type = Enums.DamageType.TOWER
	hit.amount = 10000.0
	target.health.apply(hit)
	assert_eq(score.points_for(target), -250)
	_revive()
	_kill()
	_revive()
	hit.source = target
	player.health.apply(hit)
	assert_eq(score.points_for(player), 1300)
	assert_eq(score.points_for(target), 750, "Segunda baja atribuida no da primera sangre")
