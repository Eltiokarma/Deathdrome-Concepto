extends GutTest

const VEHICLE := preload("res://entities/runner/runner.tscn")
var attacker: Runner
var victim: Runner


func before_each() -> void:
	attacker = _runner(Vector3(0, 0, 10))
	victim = _runner(Vector3.ZERO)
	await wait_physics_frames(2)


func _runner(point: Vector3) -> Runner:
	var result: Runner = VEHICLE.instantiate()
	result.position = point
	add_child_autofree(result)
	result.controller = null
	result.set_physics_process(false)
	result.get_node("RunnerCamera").set_physics_process(false)
	return result


func _damage(kind: Enums.DamageType = Enums.DamageType.LASER) -> DamageInfo:
	var info := DamageInfo.new()
	info.type = kind
	info.amount = 10.0
	info.source = attacker
	info.weapon_id = &"test"
	info.direction = Vector3.RIGHT
	return info


func test_direction_and_attacker_stats() -> void:
	var info: DamageInfo = _damage()
	info.direction = Vector3.BACK
	assert_almost_eq(victim.health.apply(info), 7.0, 0.0001, "frente")
	info.direction = Vector3.FORWARD
	assert_almost_eq(victim.health.apply(info), 12.0, 0.0001, "espalda")
	attacker.setup(&"chikchi")
	info.direction = Vector3.RIGHT
	assert_almost_eq(victim.health.apply(info), 10.5, 0.0001, "costado y stat")


func test_safe_zone_on_either_side_blocks_damage() -> void:
	var info: DamageInfo = _damage()
	attacker.health.in_safe_zone = true
	assert_eq(victim.health.apply(info), 0.0)
	attacker.health.in_safe_zone = false
	victim.health.in_safe_zone = true
	assert_eq(victim.health.apply(info), 0.0)
	assert_null(victim.health.credited_attacker())


func test_protections_and_lethal_exceptions() -> void:
	victim.health.spawn_shield_s = 3.0
	assert_eq(victim.health.apply(_damage()), 0.0)
	victim.health.spawn_shield_s = 0.0
	victim.health.armored = true
	assert_eq(victim.health.apply(_damage()), 0.0)
	victim.health.in_safe_zone = true
	assert_eq(victim.health.apply(_damage(Enums.DamageType.BARRIER)), 0.0)
	victim.health.in_safe_zone = false
	assert_eq(victim.health.apply(_damage(Enums.DamageType.BARRIER)), 100.0)
	victim.health.reset(100)
	victim.health.in_safe_zone = true
	victim.health.armored = true
	victim.health.spawn_shield_s = 3.0
	assert_eq(victim.health.apply(_damage(Enums.DamageType.PURGE)), 100.0)


func test_self_damage_exceptions_and_environment_attribution() -> void:
	var info: DamageInfo = _damage()
	info.source = victim
	assert_eq(victim.health.apply(info), 0.0)
	info.type = Enums.DamageType.RAM
	assert_eq(victim.health.apply(info), 10.0)
	victim.health.apply(_damage())
	info.type = Enums.DamageType.TOWER
	info.amount = 1000
	victim.health.apply(info)
	assert_eq(victim.health.credited_attacker(), attacker)


func test_attribution_expires_and_environment_does_not_steal_it() -> void:
	victim.health.apply(_damage())
	victim.health.tick(4.9)
	var info: DamageInfo = _damage(Enums.DamageType.MAGMA)
	info.source = null
	victim.health.apply(info)
	assert_eq(victim.health.credited_attacker(), attacker)
	victim.health.tick(0.2)
	assert_null(victim.health.credited_attacker())


func test_destroyed_emits_once_and_unattributed_death_has_no_killer() -> void:
	watch_signals(EventBus)
	var info: DamageInfo = _damage(Enums.DamageType.TOWER)
	info.source = victim
	info.amount = 1000
	victim.health.apply(info)
	victim.health.apply(info)
	assert_signal_emit_count(EventBus, "runner_destroyed", 1)
	assert_null(victim.health.credited_attacker())
	assert_eq(victim.current_integrity, 0.0)


func test_autoaim_selects_center_and_respects_world_occlusion() -> void:
	var side: Runner = _runner(Vector3(1.5, 0, 0))
	await wait_physics_frames(2)
	assert_eq(attacker.laser.acquire_target(), victim)
	victim.health.in_safe_zone = true
	assert_eq(attacker.laser.acquire_target(), side)
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 0.5, 5)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 3, 1)
	shape.shape = box
	wall.add_child(shape)
	add_child_autofree(wall)
	await wait_physics_frames(2)
	assert_null(attacker.laser.acquire_target())


func test_autoaim_rejects_outside_cone_and_range() -> void:
	victim.position = Vector3(10, 0, 0)
	await wait_physics_frames(2)
	assert_null(attacker.laser.acquire_target())
	victim.position = Vector3(0, 0, -70)
	await wait_physics_frames(2)
	assert_null(attacker.laser.acquire_target())


func test_laser_real_shots_match_continuous_ttk_with_one_shot_tolerance() -> void:
	victim.rotation.y = PI / 2.0
	victim.health.reset(100)
	var seconds: float = 0.0
	while not victim.health.destroyed and seconds < 6.0:
		attacker.laser.tick(1.0 / 60.0, true)
		seconds += 1.0 / 60.0
	assert_true(victim.health.destroyed)
	assert_almost_eq(seconds, 4.6666667, 0.125)
	assert_eq(victim.health.credited_attacker(), attacker)


func test_ramp_resets_after_gap_and_target_switch() -> void:
	victim.health.reset(1000)
	for i: int in 120:
		attacker.laser.tick(1.0 / 60.0, true)
	assert_almost_eq(attacker.laser.get("_ramp_time"), 2.0, 0.001)
	attacker.laser.tick(0.41, false)
	assert_eq(attacker.laser.get("_ramp_time"), 0.0)
	attacker.laser.tick(0.125, true)
	assert_almost_eq(attacker.laser.get("_ramp_time"), 0.125, 0.001)
	victim.health.in_safe_zone = true
	_runner(Vector3(0.5, 0, 1))
	await wait_physics_frames(2)
	attacker.laser.tick(0.125, true)
	assert_almost_eq(attacker.laser.get("_ramp_time"), 0.125, 0.001)


func test_continuous_curve_matches_table_for_all_integrities_and_directions() -> void:
	for hp: float in [70.0, 85.0, 100.0, 115.0, 130.0]:
		for multiplier: float in [0.7, 1.0, 1.2]:
			var seconds: float = 2.0 + (hp / multiplier - 36.0) / 24.0
			assert_almost_eq(attacker.laser.integrated_damage(seconds) * multiplier, hp, 0.001)


func test_firing_breaks_spawn_shield_but_not_safe_zone() -> void:
	attacker.health.spawn_shield_s = 3.0
	attacker.laser.tick(0.125, true)
	assert_eq(attacker.health.spawn_shield_s, 0.0)
	attacker.health.in_safe_zone = true
	var before: float = victim.current_integrity
	attacker.laser.tick(1.0, true)
	assert_eq(victim.current_integrity, before)
