extends GutTest

const RUNNER := preload("res://entities/runner/runner.tscn")
var manager: RoundManager
var progress: RoundProgress
var player: Runner
var target: Runner


func before_each() -> void:
	manager = add_child_autofree(RoundManager.new())
	manager.set_physics_process(false)
	progress = RoundProgress.new()
	manager.add_child(progress)
	player = add_child_autofree(RUNNER.instantiate())
	target = add_child_autofree(RUNNER.instantiate())
	player.set_physics_process(false)
	target.set_physics_process(false)
	progress.register(player)
	progress.register(target)
	manager.begin(1, 1)
	manager.tick(7.0)
	watch_signals(EventBus)


func _kill(victim: Runner, killer: Runner) -> void:
	var info := DamageInfo.new()
	info.type = Enums.DamageType.PURGE
	info.source = killer
	victim.health.apply(info)


func test_two_attributed_lives_reach_quota_once_and_allow_more_kills() -> void:
	for index: int in range(3):
		_kill(target, player)
		assert_eq(progress.kills_for(player), index + 1)
		target.reset_at(Vector3.ZERO)
	assert_true(progress.has_quota(player))
	assert_signal_emit_count(EventBus, "quota_reached", 1)
	assert_signal_emitted_with_parameters(EventBus, "quota_reached", [player])
	assert_signal_emit_count(EventBus, "quota_progress_changed", 3)
	assert_eq(manager.state, RoundManager.State.PLAYING)


func test_duplicate_signal_and_registration_do_not_inflate_or_clear_progress() -> void:
	_kill(target, player)
	EventBus.runner_destroyed.emit(target, player, &"laser")
	progress.register(player)
	assert_eq(progress.kills_for(player), 1)
	assert_signal_emit_count(EventBus, "quota_progress_changed", 1)


func test_environment_suicide_and_unregistered_participants_do_not_count() -> void:
	_kill(target, null)
	EventBus.runner_destroyed.emit(target, player, &"laser")
	assert_eq(progress.kills_for(player), 0, "Sin crédito retroactivo")
	target.reset_at(Vector3.ZERO)
	var self_hit := DamageInfo.new()
	self_hit.type = Enums.DamageType.TOWER
	self_hit.source = target
	self_hit.amount = 1000.0
	target.health.apply(self_hit)
	assert_true(target.health.destroyed)
	assert_eq(progress.kills_for(target), 0)
	var outsider: Runner = add_child_autofree(RUNNER.instantiate())
	outsider.set_physics_process(false)
	_kill(outsider, player)
	assert_eq(progress.kills_for(player), 0)
	target.reset_at(Vector3.ZERO)
	_kill(target, outsider)
	assert_false(progress.has_quota(outsider))
	assert_eq(progress.kills_for(outsider), 0)


func test_real_health_attribution_for_environment_and_expiry() -> void:
	var hit := DamageInfo.new()
	hit.source = player
	hit.amount = 1.0
	hit.direction = Vector3.FORWARD
	target.health.apply(hit)
	_kill(target, null)
	assert_eq(progress.kills_for(player), 1)
	target.reset_at(Vector3.ZERO)
	target.health.apply(hit)
	target.health.tick(5.01)
	_kill(target, null)
	assert_eq(progress.kills_for(player), 1)


func test_mercy_kill_does_not_count_and_progress_survives_player_death() -> void:
	_kill(target, player)
	EventBus.mercy_kill.emit(player, target)
	_kill(player, target)
	player.reset_at(Vector3.ZERO)
	assert_eq(progress.kills_for(player), 1)
	assert_eq(progress.kills_for(target), 1)


func test_purge_counts_but_results_and_intro_do_not_and_new_round_resets() -> void:
	manager.tick(300.0)
	_kill(target, player)
	assert_eq(progress.kills_for(player), 1)
	manager.finish({})
	target.reset_at(Vector3.ZERO)
	_kill(target, player)
	assert_eq(progress.kills_for(player), 1)
	manager.begin(1, 2)
	assert_eq(progress.kills_for(player), 0)
	assert_false(progress.has_quota(player))
	target.reset_at(Vector3.ZERO)
	_kill(target, player)
	assert_eq(progress.kills_for(player), 0)


func test_round_scene_updates_hud_on_actual_death() -> void:
	var scene: Node3D = add_child_autofree(load(
		"res://levels/_test/round_sandbox.tscn").instantiate())
	scene.round_manager.set_physics_process(false)
	scene.round_manager.tick(7.0)
	_kill(scene.target, scene.runner)
	scene._process(0.0)
	assert_string_contains(scene.round_label.text, "BAJAS 1 / 2")
