extends GutTest

var scene: Node3D
var portal: RoundPortal
var player: Runner
var target: Runner


func before_each() -> void:
	scene = add_child_autofree(load("res://levels/_test/round_sandbox.tscn").instantiate())
	portal = scene.portal
	player = scene.runner
	target = scene.target
	scene.round_manager.set_physics_process(false)
	portal.set_physics_process(false)
	scene.round_manager.tick(7.0)
	player.set_physics_process(false)
	target.set_physics_process(false)
	scene.respawner.set_physics_process(false)
	watch_signals(EventBus)
	await wait_physics_frames(2)


func _earn_quota() -> void:
	for index: int in range(2):
		var hit := DamageInfo.new()
		hit.type = Enums.DamageType.PURGE
		hit.source = player
		target.health.apply(hit)
		target.reset_at(Vector3(-17, 0.1, 0))
	portal.tick(0.0)


func test_closed_gate_physically_blocks_unqualified_runner() -> void:
	player.position = Vector3(-7, 0.1, 15)
	await wait_physics_frames(2)
	var collision: KinematicCollision3D = player.move_and_collide(Vector3(8, 0, 0))
	assert_not_null(collision)
	assert_eq(collision.get_collider(), portal.gate)
	assert_false(portal.eligible(player))
	portal._on_entered(player)
	assert_false(portal.is_ascending(player))
	assert_signal_not_emitted(EventBus, "runner_escaped")


func test_qualified_player_passes_gate_but_other_runner_stays_blocked() -> void:
	_earn_quota()
	assert_true(portal.eligible(player))
	assert_false(portal.eligible(target))
	player.position = Vector3(-7, 0.1, 15)
	await wait_physics_frames(2)
	assert_null(player.move_and_collide(Vector3(6, 0, 0)))
	await wait_physics_frames(3)
	assert_true(portal.is_ascending(player), "Area detecta entrada física")
	assert_false(player.is_physics_processing())
	assert_eq(player.collision_layer, 0)
	assert_false(player.is_in_group("runners"))
	target.position = Vector3(7, 0.1, 15)
	await wait_physics_frames(2)
	var collision: KinematicCollision3D = target.move_and_collide(Vector3(-8, 0, 0))
	assert_not_null(collision)
	assert_eq(collision.get_collider(), portal.gate)


func test_ascent_pause_single_escape_and_entry_clock_snapshot() -> void:
	_earn_quota()
	var entry_time: float = scene.round_manager.seconds_left
	portal._on_entered(player)
	portal._on_entered(player)
	get_tree().paused = true
	portal.tick(10.0)
	get_tree().paused = false
	assert_signal_not_emitted(EventBus, "runner_escaped")
	scene.round_manager.tick(2.0)
	portal.tick(2.9)
	assert_signal_not_emitted(EventBus, "runner_escaped")
	portal.tick(0.1)
	portal.tick(10.0)
	assert_signal_emit_count(EventBus, "runner_escaped", 1)
	assert_signal_emitted_with_parameters(EventBus, "runner_escaped", [player, entry_time])
	assert_eq(scene.round_manager.state, RoundManager.State.RESULTS)
	assert_false(portal.is_ascending(player))


func test_new_round_restores_collision_group_and_closes_gate() -> void:
	_earn_quota()
	portal._on_entered(player)
	await wait_physics_frames(1)
	portal.tick(3.0)
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	scene._unhandled_input(event)
	portal.tick(0.0)
	assert_eq(scene.round_manager.state, RoundManager.State.INTRO)
	assert_eq(player.collision_layer, 2)
	assert_true(player.is_in_group("runners"))
	assert_false(portal.eligible(player))
	assert_false(player.get_collision_exceptions().has(portal.gate))
	assert_eq(player.position, scene.SPAWN)


func test_purge_allows_escape_but_dead_runner_is_rejected() -> void:
	_earn_quota()
	scene.round_manager.tick(300.0)
	assert_true(portal.eligible(player))
	player.health.destroyed = true
	assert_false(portal.eligible(player))
	portal._on_entered(player)
	assert_false(portal.is_ascending(player))


func test_external_end_cancels_pending_escape() -> void:
	_earn_quota()
	portal._on_entered(player)
	scene.round_manager.finish({"reason": "abort"})
	portal.tick(10.0)
	assert_signal_not_emitted(EventBus, "runner_escaped")
	assert_false(portal.is_ascending(player))
