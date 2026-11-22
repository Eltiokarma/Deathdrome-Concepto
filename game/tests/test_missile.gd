extends GutTest
## Fijacion, impactos barridos y perdida de guia sin depender de una arena concreta.

const VEHICLE := preload("res://entities/runner/runner.tscn")

var attacker: Runner
var victim: Runner
var lock_system: MissileLock


func before_each() -> void:
	attacker = _runner(Vector3(0, 0, 10))
	victim = _runner(Vector3.ZERO)
	lock_system = MissileLock.new()
	lock_system.name = "MissileLockTest"
	attacker.add_child(lock_system)
	await wait_physics_frames(2)


func test_lock_requires_full_time_and_emits_single_start_and_loss() -> void:
	watch_signals(EventBus)
	var duration: float = attacker.stats.missile_lock_time_s
	lock_system.tick(duration * 0.5, true)
	assert_eq(lock_system.target, victim)
	assert_almost_eq(lock_system.progress, 0.5, 0.001)
	assert_null(lock_system.locked_target())
	lock_system.tick(duration * 0.5, true)
	assert_eq(lock_system.locked_target(), victim)
	lock_system.tick(duration, true)
	assert_almost_eq(lock_system.progress, 1.0, 0.001)
	assert_signal_emit_count(EventBus, "lock_started", 1)
	lock_system.tick(0.1, false)
	lock_system.reset()
	assert_null(lock_system.target)
	assert_null(lock_system.locked_target())
	assert_eq(lock_system.progress, 0.0)
	assert_signal_emit_count(EventBus, "lock_lost", 1)


func test_lock_rejects_cone_range_and_world_occlusion() -> void:
	victim.position = Vector3(20, 0, 0)
	await wait_physics_frames(2)
	lock_system.tick(1.0, true)
	assert_null(lock_system.target, "Fuera del cono")
	victim.position = Vector3(0, 0, 10.0 - Balance.get_f("weapons.missile.lock_range_m") - 5.0)
	await wait_physics_frames(2)
	lock_system.tick(1.0, true)
	assert_null(lock_system.target, "Fuera del alcance")
	victim.position = Vector3.ZERO
	var wall: StaticBody3D = _wall(Vector3(0, 0.5, 5))
	await wait_physics_frames(2)
	lock_system.tick(1.0, true)
	assert_null(lock_system.target, "La pared bloquea la fijacion")
	wall.queue_free()
	await wait_physics_frames(2)
	lock_system.tick(attacker.stats.missile_lock_time_s, true)
	assert_eq(lock_system.locked_target(), victim)


func test_target_change_and_protected_or_escaped_targets_reset_lock() -> void:
	var side: Runner = _runner(Vector3(2, 0, 0))
	await wait_physics_frames(2)
	lock_system.tick(attacker.stats.missile_lock_time_s, true)
	assert_eq(lock_system.locked_target(), victim)
	victim.health.in_safe_zone = true
	lock_system.tick(attacker.stats.missile_lock_time_s * 0.25, true)
	assert_eq(lock_system.target, side)
	assert_null(lock_system.locked_target(), "Cambiar blanco no conserva la fijacion completa")
	assert_almost_eq(lock_system.progress, 0.25, 0.001)
	side.health.cloaked = true
	lock_system.tick(1.0, true)
	assert_null(lock_system.target, "No fija camuflados ni protegidos por zona franca")
	side.health.cloaked = false
	side.health.destroyed = true
	lock_system.tick(1.0, true)
	assert_null(lock_system.target, "No fija destruidos")
	side.health.destroyed = false
	side.remove_from_group("runners")
	lock_system.tick(1.0, true)
	assert_null(lock_system.target, "Un ascenso o escape sale del grupo de blancos")


func test_direct_missile_hits_once_and_excludes_its_owner() -> void:
	var projectile: MissileProjectile = _projectile()
	var before: float = victim.health.current
	projectile.tick(1.0)
	assert_eq(victim.health.current, before - Balance.get_f("weapons.missile.damage"))
	assert_eq(victim.health.credited_attacker(), attacker)
	assert_eq(attacker.health.current, attacker.health.maximum, "Nace dentro del tirador")
	assert_true(projectile.is_queued_for_deletion())
	projectile.tick(1.0)
	assert_eq(victim.health.current, before - Balance.get_f("weapons.missile.damage"))


func test_swept_missile_stops_at_wall_before_target_even_with_large_step() -> void:
	_wall(Vector3(0, 0.5, 5))
	await wait_physics_frames(2)
	var projectile: MissileProjectile = _projectile()
	projectile.tick(1.0)
	assert_true(projectile.is_queued_for_deletion())
	assert_eq(victim.health.current, victim.health.maximum, "No atraviesa la pared")
	assert_gt(projectile.global_position.z, victim.global_position.z)


func test_direct_hits_respect_shield_armor_and_safe_zone() -> void:
	for protection: String in ["shield", "armor", "victim_safe", "attacker_safe"]:
		victim.health.reset(victim.health.maximum)
		victim.health.in_safe_zone = false
		attacker.health.in_safe_zone = false
		match protection:
			"shield":
				victim.health.spawn_shield_s = 3.0
			"armor":
				victim.health.armored = true
			"victim_safe":
				victim.health.in_safe_zone = true
			"attacker_safe":
				attacker.health.in_safe_zone = true
		var projectile: MissileProjectile = _projectile()
		projectile.tick(1.0)
		assert_eq(victim.health.current, victim.health.maximum, protection)
		assert_null(victim.health.credited_attacker(), protection)


func test_guidance_obeys_turn_rate_and_moves_at_configured_speed() -> void:
	victim.global_position = Vector3(20, 0, 10)
	await wait_physics_frames(2)
	var projectile: MissileProjectile = _projectile(victim)
	var origin: Vector3 = projectile.global_position
	var delta: float = 0.1
	projectile.tick(delta)
	var turned: float = Vector3.FORWARD.angle_to(projectile.direction)
	var allowed: float = deg_to_rad(Balance.get_f("weapons.missile.turn_rate_deg_s")) * delta
	assert_gt(turned, 0.0, "Comienza a girar hacia el blanco")
	assert_lte(turned, allowed + 0.0001, "La fijacion no permite giros instantaneos")
	assert_almost_eq(projectile.global_position.distance_to(origin),
			Balance.get_f("weapons.missile.speed_mps") * delta, 0.001)
	assert_almost_eq(projectile.remaining,
			Balance.get_f("weapons.missile.lifetime_s") - delta, 0.001)


func test_target_invalidation_cuts_guidance_including_a_new_life() -> void:
	victim.global_position = Vector3(20, 0, 10)
	await wait_physics_frames(2)
	for reason: String in ["dead", "safe", "cloak", "escaped", "respawn"]:
		victim.health.reset(victim.health.maximum)
		victim.health.in_safe_zone = false
		victim.health.cloaked = false
		if not victim.is_in_group("runners"):
			victim.add_to_group("runners")
		var projectile: MissileProjectile = _projectile(victim)
		match reason:
			"dead":
				victim.health.destroyed = true
			"safe":
				victim.health.in_safe_zone = true
			"cloak":
				victim.health.cloaked = true
			"escaped":
				victim.remove_from_group("runners")
			"respawn":
				victim.health.reset(victim.health.maximum)
		projectile.tick(0.1)
		assert_eq(projectile.direction, Vector3.FORWARD, reason)
		projectile.queue_free()


func test_owner_new_life_cancels_old_projectile_before_damage() -> void:
	var projectile: MissileProjectile = _projectile()
	attacker.reset_at(attacker.global_position)
	projectile.tick(1.0)
	assert_true(projectile.is_queued_for_deletion())
	assert_eq(victim.health.current, victim.health.maximum)
	assert_null(victim.health.credited_attacker())


func test_guided_missile_reaches_fleeing_kuntur_from_lock_range_before_expiry() -> void:
	victim.setup(&"kuntur")
	var origin: Vector3 = attacker.laser.global_position
	var collider: CollisionShape3D = victim.get_node("CollisionShape3D")
	var distance: float = Balance.get_f("weapons.missile.lock_range_m")
	# Centro del casco a la misma altura y exactamente a alcance de fijacion del muzzle.
	victim.global_position = origin + Vector3.FORWARD * distance - collider.position
	await wait_physics_frames(2)
	assert_almost_eq(origin.distance_to(collider.global_position), distance, 0.001)
	var projectile: MissileProjectile = _projectile(victim)
	projectile.global_position = origin
	var integrity: float = victim.health.current
	var delta: float = 1.0 / 60.0
	var lifetime: float = Balance.get_f("weapons.missile.lifetime_s")
	for _frame: int in range(ceili(lifetime / delta)):
		victim.global_position += Vector3.FORWARD * victim.stats.max_speed_mps * delta
		# Sincronizar el cuerpo con el espacio fisico antes del siguiente barrido.
		await wait_physics_frames(1)
		projectile.tick(delta)
		if projectile.is_queued_for_deletion():
			break
	assert_true(projectile.is_queued_for_deletion(), "Alcanza al Runner que huye a maxima velocidad")
	assert_gt(projectile.remaining, 0.0, "Impacta antes de agotar su vida, no por caducidad")
	assert_eq(victim.health.current, integrity - Balance.get_f("weapons.missile.damage"))
	assert_eq(victim.health.credited_attacker(), attacker)


func test_pause_invalid_time_and_lifetime_cannot_extend_flight() -> void:
	var projectile: MissileProjectile = _projectile(null, Vector3.RIGHT)
	var origin: Vector3 = projectile.global_position
	var lifetime: float = Balance.get_f("weapons.missile.lifetime_s")
	for delta: float in [-1.0, NAN, INF]:
		projectile.tick(delta)
	assert_eq(projectile.global_position, origin)
	assert_eq(projectile.remaining, lifetime)
	get_tree().paused = true
	projectile.tick(1.0)
	get_tree().paused = false
	assert_eq(projectile.global_position, origin)
	projectile.tick(lifetime + 10.0)
	assert_true(projectile.is_queued_for_deletion())
	assert_almost_eq(projectile.remaining, 0.0, 0.001)
	assert_almost_eq(projectile.global_position.distance_to(origin),
			Balance.get_f("weapons.missile.speed_mps") * lifetime, 0.001)


func _runner(point: Vector3) -> Runner:
	var result: Runner = VEHICLE.instantiate()
	result.position = point
	add_child_autofree(result)
	result.controller = null
	result.set_physics_process(false)
	result.get_node("RunnerCamera").set_physics_process(false)
	return result


func _projectile(target: Runner = null, direction: Vector3 = Vector3.FORWARD) -> MissileProjectile:
	var result := MissileProjectile.new()
	add_child_autofree(result)
	result.global_position = attacker.global_position + Vector3.UP * 0.35
	result.setup(attacker, direction, target)
	result.set_physics_process(false)
	return result


func _wall(point: Vector3) -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.position = point
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 3, 1)
	collider.shape = box
	wall.add_child(collider)
	add_child_autofree(wall)
	return wall
