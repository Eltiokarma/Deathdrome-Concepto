extends GutTest

const SANDBOX := preload("res://levels/_test/driving_sandbox.tscn")
var sandbox: Node3D
var respawner: PracticeRespawner
var target: Runner
var player: Runner


func before_each() -> void:
	sandbox = add_child_autofree(SANDBOX.instantiate())
	target = sandbox.get_node("Target")
	player = sandbox.get_node("Runner")
	respawner = sandbox.get_node("PracticeRespawner")
	respawner.set_physics_process(false)
	target.set_physics_process(false)
	player.set_physics_process(false)
	await wait_physics_frames(2)


func _destroy_target() -> void:
	var info := DamageInfo.new()
	info.type = Enums.DamageType.PURGE
	info.source = player
	target.health.apply(info)


func test_respawns_once_after_configured_delay_with_shield() -> void:
	watch_signals(EventBus)
	_destroy_target()
	assert_true(respawner.pending)
	respawner.tick(Balance.get_f("respawn.delay_s") - 0.01)
	assert_true(target.health.destroyed)
	respawner.tick(0.02)
	assert_false(target.health.destroyed)
	assert_eq(target.current_integrity, target.stats.max_integrity)
	assert_eq(target.health.spawn_shield_s, Balance.get_f("respawn.spawn_shield_s"))
	assert_null(target.health.credited_attacker())
	assert_true(target.get_collision_layer_value(2))
	assert_signal_emit_count(EventBus, "runner_respawned", 1)
	respawner.tick(10.0)
	assert_signal_emit_count(EventBus, "runner_respawned", 1)


func test_pause_freezes_respawn_countdown() -> void:
	_destroy_target()
	var before: float = respawner.remaining
	get_tree().paused = true
	respawner.tick(10.0)
	var after: float = respawner.remaining
	get_tree().paused = false
	assert_eq(after, before)
	assert_true(target.health.destroyed)


func test_occupied_spawn_waits_then_recovers() -> void:
	_destroy_target()
	player.position = respawner.spawn_position
	await wait_physics_frames(2)
	respawner.tick(10.0)
	assert_true(respawner.blocked)
	assert_true(target.health.destroyed)
	player.position = Vector3(-17, 0.1, 15)
	await wait_physics_frames(2)
	respawner.tick(0.01)
	assert_false(target.health.destroyed)
	assert_false(respawner.pending)


func test_manual_reset_cancels_pending_respawn() -> void:
	watch_signals(EventBus)
	_destroy_target()
	var event := InputEventAction.new()
	event.action = "reset_runner"
	event.pressed = true
	sandbox._unhandled_input(event)
	assert_false(respawner.pending)
	assert_false(target.health.destroyed)
	respawner.tick(10.0)
	assert_signal_not_emitted(EventBus, "runner_respawned")


func test_spawn_shield_blocks_laser_until_expiry() -> void:
	_destroy_target()
	respawner.tick(10.0)
	var info := DamageInfo.new()
	info.source = player
	info.amount = 10.0
	info.direction = Vector3.FORWARD
	assert_eq(target.health.apply(info), 0.0)
	target.health.tick(Balance.get_f("respawn.spawn_shield_s"))
	assert_gt(target.health.apply(info), 0.0)
