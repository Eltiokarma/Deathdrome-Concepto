extends GutTest

const RUNNER := preload("res://entities/runner/runner.tscn")
const SANDBOX := preload("res://levels/_test/round_sandbox.tscn")

var root: Node3D
var clock: RoundManager
var field: PurgeField
var player: Runner


func before_each() -> void:
	root = add_child_autofree(Node3D.new())
	clock = RoundManager.new()
	clock.name = "Clock"
	root.add_child(clock)
	clock.set_physics_process(false)
	field = load("res://round/purge_field.tscn").instantiate()
	field.manager_path = NodePath("../Clock")
	field.start_radius = 42.0
	root.add_child(field)
	field.set_physics_process(false)
	player = RUNNER.instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	clock.begin(1, 1)
	clock.tick(7.0)


func test_speed_and_ten_second_hub_closure() -> void:
	clock.tick(300.0)
	field.tick(2.0)
	assert_eq(field.radius, 35.0)
	field.tick(8.0)
	assert_eq(field.radius, 7.0)
	field.tick(9.99)
	assert_gt(field.radius, 0.0)
	assert_false(player.health.destroyed)
	field.tick(0.02)
	assert_eq(field.radius, 0.0)
	assert_true(player.health.destroyed, "También mata en el centro exacto")


func test_domain_eight_speed_keeps_ten_second_hub_closure() -> void:
	clock.finish({})
	clock.begin(8, 1)
	clock.tick(307.0)
	field.tick(2.0)
	assert_eq(field.radius, 31.5)
	field.tick(35.0 / 5.25 - 2.0)
	assert_almost_eq(field.radius, 7.0, 0.00001)
	field.tick(5.0)
	assert_almost_eq(field.radius, 3.5, 0.00001)


func test_large_step_matches_partitioned_time_and_closes_once() -> void:
	clock.tick(300.0)
	field.tick(15.0)
	var expected: float = field.radius
	field.reset()
	for index: int in range(60):
		field.tick(0.25)
	assert_almost_eq(field.radius, expected, 0.00001)
	watch_signals(EventBus)
	field.tick(100.0)
	field.tick(100.0)
	assert_signal_emit_count(EventBus, "purge_closed", 1)


func test_purge_ignores_safe_zone_shield_armor_and_height() -> void:
	clock.tick(300.0)
	player.health.in_safe_zone = true
	player.health.spawn_shield_s = 3.0
	player.health.armored = true
	player.position = Vector3(30, 1000, 0)
	field.tick(4.0)
	assert_true(player.health.destroyed)
	player.reset_at(Vector3(30, -1000, 0))
	field.tick(0.0)
	assert_true(player.health.destroyed)


func test_pause_invalid_delta_and_results_freeze_field() -> void:
	clock.tick(300.0)
	get_tree().paused = true
	field.tick(100.0)
	get_tree().paused = false
	for delta: float in [NAN, INF, -1.0]:
		field.tick(delta)
	assert_eq(field.radius, 42.0)
	clock.finish({})
	field.tick(100.0)
	assert_eq(field.radius, 42.0)
	assert_false(field.get_node("Wall").visible)


func test_warning_and_new_round_reset() -> void:
	clock.tick(269.0)
	assert_false(field._warned)
	clock.tick(1.0)
	assert_true(field._warned)
	assert_gt(field.get_node("Warning").stream.get_length(), 0.0)
	clock.tick(30.0)
	field.tick(2.0)
	clock.finish({})
	clock.begin(1, 2)
	assert_eq(field.radius, 42.0)
	assert_false(field._warned)
	assert_false(field.closed)
	assert_false(field.get_node("Wall").visible)


func test_last_attacker_attribution_is_preserved() -> void:
	var attacker: Runner = RUNNER.instantiate()
	root.add_child(attacker)
	attacker.set_physics_process(false)
	clock.tick(300.0)
	player.position.x = 41.0
	var hit := DamageInfo.new()
	hit.source = attacker
	hit.amount = 1.0
	hit.direction = Vector3.RIGHT
	player.health.apply(hit)
	field.tick(1.0)
	assert_true(player.health.destroyed)
	assert_eq(player.health.credited_attacker(), attacker)


func test_sandbox_blocks_respawn_reset_and_finishes_on_player_death() -> void:
	var scene: Node3D = add_child_autofree(SANDBOX.instantiate())
	scene.round_manager.set_physics_process(false)
	scene.purge.set_physics_process(false)
	scene.round_manager.tick(307.0)
	var damage := DamageInfo.new()
	damage.type = Enums.DamageType.PURGE
	scene.target.health.apply(damage)
	assert_false(scene.respawner.pending)
	scene.respawner.tick(100.0)
	assert_true(scene.target.health.destroyed)
	scene.runner.position.x = 100.0
	scene.purge.tick(0.1)
	assert_eq(scene.round_manager.state, RoundManager.State.RESULTS)
	assert_eq(scene.score.points_for(scene.runner), -250)
	var reset := InputEventAction.new()
	reset.action = "reset_runner"
	reset.pressed = true
	scene._unhandled_input(reset)
	assert_true(scene.runner.health.destroyed)
	assert_false(scene.runner.model.visible)


func test_admitted_runner_finishes_ascent_after_full_closure() -> void:
	var scene: Node3D = add_child_autofree(SANDBOX.instantiate())
	scene.round_manager.set_physics_process(false)
	scene.purge.set_physics_process(false)
	scene.portal.set_physics_process(false)
	scene.round_manager.tick(7.0)
	for index: int in range(2):
		scene.target.reset_at(Vector3(-17, 0.1, 0))
		var damage := DamageInfo.new()
		damage.type = Enums.DamageType.PURGE
		damage.source = scene.runner
		scene.target.health.apply(damage)
	scene.round_manager.tick(300.0)
	scene.portal._on_entered(scene.runner)
	scene.purge.tick(100.0)
	assert_false(scene.runner.health.destroyed)
	assert_eq(scene.round_manager.state, RoundManager.State.PURGE)
	scene.portal.tick(3.0)
	assert_eq(scene.round_manager.state, RoundManager.State.RESULTS)
	assert_eq(scene.score.points_for(scene.runner), 5300)
