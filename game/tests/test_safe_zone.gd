extends GutTest

const RUNNER := preload("res://entities/runner/runner.tscn")
const ZONE := preload("res://entities/zones/safe_zone.tscn")
var zone: SafeZone
var player: Runner
var target: Runner
var manager: RoundManager


func before_each() -> void:
	zone = add_child_autofree(ZONE.instantiate())
	zone.radius = 5.0
	player = add_child_autofree(RUNNER.instantiate())
	target = add_child_autofree(RUNNER.instantiate())
	player.set_physics_process(false)
	target.set_physics_process(false)
	player.position = Vector3(0, 0.1, 0)
	target.position = Vector3(0, 0.1, -15)
	manager = add_child_autofree(RoundManager.new())
	manager.set_physics_process(false)
	zone.manager = manager


func test_entry_exit_and_teleport_apply_without_waiting_for_physics() -> void:
	assert_true(player.health.in_safe_zone)
	player.position.x = 5.01
	assert_false(player.health.in_safe_zone)
	player.reset_at(Vector3(0, 0.1, 0))
	assert_true(player.health.in_safe_zone)
	player.position.y = 7.0
	assert_false(player.health.in_safe_zone)
	player.position = Vector3(0, 2.5, 0)
	assert_true(player.health.in_safe_zone, "Saltar no desactiva protección")


func test_protects_both_attacker_and_victim_except_purge() -> void:
	var hit := DamageInfo.new()
	hit.source = player
	hit.amount = 10.0
	hit.direction = Vector3.FORWARD
	assert_eq(target.health.apply(hit), 0.0, "No dispara hacia fuera")
	hit.source = target
	assert_eq(player.health.apply(hit), 0.0, "No recibe daño desde fuera")
	hit.type = Enums.DamageType.BARRIER
	assert_eq(player.health.apply(hit), 0.0)
	hit.type = Enums.DamageType.PURGE
	assert_gt(player.health.apply(hit), 0.0)
	assert_true(player.health.destroyed)


func test_laser_does_not_fire_or_consume_spawn_shield_inside() -> void:
	player.health.spawn_shield_s = 3.0
	player.laser.tick(1.0, true)
	assert_eq(player.health.spawn_shield_s, 3.0)
	assert_null(player.laser.target)
	assert_eq(target.current_integrity, target.stats.max_integrity)
	player.position.x = 6.0
	target.position.x = 6.0
	await wait_physics_frames(2)
	player.laser.tick(0.125, true)
	assert_eq(player.health.spawn_shield_s, 0.0)
	assert_lt(target.current_integrity, target.stats.max_integrity)


func test_off_and_round_start_modes_follow_round_clock() -> void:
	zone.policy = "off"
	assert_false(player.health.in_safe_zone)
	zone.policy = "round_start"
	assert_false(zone.active(), "No activa en LOADING")
	manager.begin(1, 1)
	assert_true(zone.active())
	manager.tick(7.0)
	assert_true(zone.active())
	manager.tick(9.99)
	assert_true(zone.active())
	get_tree().paused = true
	manager.tick(20.0)
	get_tree().paused = false
	assert_true(zone.active())
	manager.tick(0.02)
	assert_false(zone.active())
	manager.tick(300.0)
	assert_false(zone.active())
	manager.finish({})
	manager.begin(1, 2)
	assert_true(zone.active())


func test_overlap_and_removal_do_not_leave_stale_protection() -> void:
	var second: SafeZone = add_child_autofree(ZONE.instantiate())
	zone.policy = "off"
	assert_true(player.health.in_safe_zone)
	remove_child(second)
	assert_false(player.health.in_safe_zone)
	add_child(second)
	assert_true(player.health.in_safe_zone)
	second.position.x = 100.0
	assert_false(player.health.in_safe_zone)


func test_zone_transform_and_boundaries() -> void:
	zone.position = Vector3(40, 0, 0)
	zone.scale = Vector3(2, 1, 2)
	player.position = Vector3(50, 0, 0)
	assert_true(player.health.in_safe_zone)
	player.position.x = 50.01
	assert_false(player.health.in_safe_zone)
