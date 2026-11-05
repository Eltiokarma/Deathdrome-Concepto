extends GutTest

const RUNNER := preload("res://entities/runner/runner.tscn")
var player: Runner
var target: Runner
var weapon: BarrierWeapon


func before_each() -> void:
	player = add_child_autofree(RUNNER.instantiate())
	target = add_child_autofree(RUNNER.instantiate())
	player.set_physics_process(false)
	target.set_physics_process(false)
	player.controller = null
	target.controller = null
	player.position = Vector3(-10, 0, 10)
	target.position = Vector3(10, 0, 10)
	weapon = player.barrier
	weapon.set_physics_process(false)
	target.barrier.set_physics_process(false)
	await wait_physics_frames(2)


func _segment() -> BarrierSegment:
	return weapon.emit_segment(Vector3(0, 0, -3), Vector3(0, 0, 3))


func test_energy_drain_delay_regeneration_and_held_exhaustion() -> void:
	var maximum: float = player.stats.barrier_energy
	weapon.tick(1.0, true)
	assert_eq(weapon.energy, maximum - 30.0)
	weapon.tick(1.0, false)
	assert_eq(weapon.energy, maximum - 30.0)
	weapon.tick(1.0, false)
	assert_eq(weapon.energy, maximum - 25.0)
	weapon.tick(100.0, false)
	assert_eq(weapon.energy, maximum)
	weapon.tick(100.0, true)
	assert_eq(weapon.energy, 0.0)
	weapon.tick(10.0, true)
	assert_eq(weapon.energy, 0.0)


func test_owner_can_cross_but_rival_hits_solid_segment_at_speed() -> void:
	var segment: BarrierSegment = _segment()
	player.position = Vector3(-5, 0.1, 0)
	await wait_physics_frames(2)
	assert_null(player.move_and_collide(Vector3(10, 0, 0)))
	assert_false(player.health.destroyed)
	target.position = Vector3(-5, 0.1, 0)
	await wait_physics_frames(2)
	var collision: KinematicCollision3D = target.move_and_collide(Vector3(20, 0, 0))
	assert_not_null(collision)
	assert_eq(collision.get_collider(), segment)
	segment.hit(target)
	assert_true(target.health.destroyed)
	assert_eq(target.health.credited_attacker(), player)


func test_runner_motor_contact_applies_lethal_damage() -> void:
	_segment()
	target.position = Vector3(-2, 0.1, 0)
	target.rotation.y = -PI / 2.0
	target.velocity = Vector3(200, 0, 0)
	await wait_physics_frames(2)
	target.set_physics_process(true)
	await wait_physics_frames(2)
	target.set_physics_process(false)
	assert_true(target.health.destroyed)


func test_high_crossing_clears_barrier_and_overlap_is_lethal() -> void:
	_segment()
	target.position = Vector3(-5, 2.5, 0)
	await wait_physics_frames(2)
	assert_null(target.move_and_collide(Vector3(10, 0, 0)))
	assert_false(target.health.destroyed)
	target.position = Vector3(0, 0.1, 0)
	await wait_physics_frames(2)
	weapon.advance_segments(0.01)
	assert_true(target.health.destroyed)


func test_segments_expire_reuse_pool_and_do_not_follow_owner() -> void:
	var segment: BarrierSegment = _segment()
	var point: Vector3 = segment.global_position
	player.position += Vector3(30, 0, 0)
	assert_eq(segment.global_position, point)
	weapon.advance_segments(3.49)
	assert_gt(segment.remaining, 0.0)
	weapon.advance_segments(0.02)
	assert_eq(segment.collision_layer, 0)
	assert_false(segment.visible)
	assert_same(_segment(), segment)
	assert_eq(weapon.get_child_count(), Balance.get_i("weapons.barrier.pool_size"))


func test_safe_zone_dissipates_crossing_segment_with_both_endpoints_outside() -> void:
	var segment: BarrierSegment = _segment()
	var zone: SafeZone = add_child_autofree(load("res://entities/zones/safe_zone.tscn").instantiate())
	zone.radius = 1.0
	weapon.advance_segments(0.01)
	assert_eq(segment.remaining, 0.0)
	assert_null(_segment())
	zone.policy = "off"
	assert_not_null(_segment())


func test_safe_zone_blocks_emission_without_breaking_shield() -> void:
	player.health.in_safe_zone = true
	player.health.spawn_shield_s = 3.0
	var before: float = weapon.energy
	weapon.tick(1.0, true)
	assert_eq(weapon.energy, before)
	assert_eq(player.health.spawn_shield_s, 3.0)
	assert_false(weapon.segments.any(func(s: BarrierSegment) -> bool: return s.remaining > 0.0))


func test_pause_freezes_energy_and_lifetime_and_reset_clears_pool() -> void:
	var segment: BarrierSegment = _segment()
	var before: float = weapon.energy
	get_tree().paused = true
	weapon.tick(10.0, true)
	weapon.advance_segments(10.0)
	get_tree().paused = false
	assert_eq(weapon.energy, before)
	assert_eq(segment.remaining, 3.5)
	weapon.reset()
	assert_eq(segment.remaining, 0.0)
	assert_eq(weapon.energy, player.stats.barrier_energy)


func test_trail_emission_and_teleport_guard() -> void:
	weapon.tick(0.05, true)
	player.position.z -= 1.0
	weapon.tick(0.05, true)
	assert_gt(weapon.segments[0].remaining, 0.0)
	player.position.z -= 100.0
	weapon.tick(0.05, true)
	assert_eq(weapon.segments[1].remaining, 0.0)


func test_pool_exhaustion_never_recycles_a_live_segment() -> void:
	for index: int in range(Balance.get_i("weapons.barrier.pool_size")):
		assert_not_null(_segment())
	assert_null(_segment())
	assert_eq(weapon.segments[0].remaining, 3.5)
	assert_eq(weapon.get_child_count(), Balance.get_i("weapons.barrier.pool_size"))


func test_trail_outlives_owner_until_expiry() -> void:
	var segment: BarrierSegment = _segment()
	var damage := DamageInfo.new()
	damage.type = Enums.DamageType.PURGE
	player.health.apply(damage)
	weapon.advance_segments(1.0)
	segment.hit(target)
	assert_true(player.health.destroyed)
	assert_true(target.health.destroyed)
	assert_eq(target.health.credited_attacker(), player)
	weapon.advance_segments(3.0)
	assert_eq(segment.remaining, 0.0)
