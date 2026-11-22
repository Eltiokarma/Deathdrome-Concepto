extends GutTest
## Explosiones de altura limitada, torres, contacto y cadenas con atribucion estable.

const RUNNER := preload("res://entities/runner/runner.tscn")
const ZONE := preload("res://entities/zones/safe_zone.tscn")

var arena: Node3D
var emitter: Node3D
var player: Runner
var target: Runner


func before_each() -> void:
	arena = add_child_autofree(Node3D.new())
	emitter = Node3D.new()
	arena.add_child(emitter)
	player = _runner(Vector3(-30, 0, 0))
	target = _runner(Vector3(30, 0, 0))
	await wait_physics_frames(2)


func test_shockwave_falloff_radius_jump_and_owner_immunity() -> void:
	var radius: float = Balance.get_f("weapons.shockwave.radius_m")
	var center: float = Balance.get_f("weapons.shockwave.damage_center")
	var edge: float = Balance.get_f("weapons.shockwave.damage_edge")
	player.reset_at(Vector3.ZERO)
	for distance: float in [0.0, radius * 0.5, radius]:
		target.reset_at(Vector3(distance, 0, 0))
		BlastDamage.apply(emitter, player, &"shockwave")
		var expected: float = lerpf(center, edge, distance / radius)
		assert_almost_eq(target.health.current, target.health.maximum - expected, 0.001)
		assert_eq(player.health.current, player.health.maximum, "La onda no causa autodaño")
	for point: Vector3 in [Vector3(radius + 0.1, 0, 0), Vector3(2, 2.5, 0),
			Vector3(2, -1.0, 0)]:
		target.reset_at(point)
		BlastDamage.apply(emitter, player, &"shockwave")
		assert_eq(target.health.current, target.health.maximum, "Fuera del cilindro: %s" % point)


func test_blast_does_not_cross_a_wall_or_a_platform() -> void:
	target.reset_at(Vector3(4, 0, 0))
	var wall: StaticBody3D = _box(Vector3(2, 1, 0), Vector3(0.4, 3, 4))
	var tower: FusionTower = _tower(Vector3(4, 0, 3))
	await wait_physics_frames(2)
	BlastDamage.apply(emitter, player, &"shockwave")
	assert_eq(target.health.current, target.health.maximum, "La pared bloquea la onda")
	assert_true(tower.charged, "La onda tampoco detona torres a traves de paredes")
	tower.queue_free()
	wall.queue_free()
	await wait_physics_frames(2)
	_box(Vector3(2, 1.0, 0), Vector3(10, 0.2, 10))
	target.reset_at(Vector3(4, 1.11, 0))
	await wait_physics_frames(2)
	BlastDamage.apply(emitter, player, &"shockwave")
	assert_eq(target.health.current, target.health.maximum,
			"Estar dentro de la altura no permite atravesar el suelo de una plataforma")


func test_ground_wave_overlaps_lower_bodies_but_airborne_wave_misses_towers() -> void:
	var first: FusionTower = _tower(Vector3(6, 0, 0))
	var second: FusionTower = _tower(Vector3(12, 0, 0))
	player.reset_at(Vector3(0, 0.1, 0))
	target.reset_at(Vector3(0, 0, 4))
	await wait_physics_frames(2)
	BlastDamage.apply(player, player, &"shockwave")
	assert_false(first.charged, "Los cuerpos de torre y onda se solapan pese al desnivel de 0.1")
	assert_lt(target.health.current, target.health.maximum, "Tambien alcanza al Runner mas bajo")
	assert_true(second.charged, "La segunda torre queda fuera del radio directo de la onda")
	second.tick(Balance.get_f("hazards.fusion_tower.chain_delay_s") + 0.01)
	assert_false(second.charged, "La torre a ras de suelo propaga la cadena")
	first.reset()
	second.reset()
	player.reset_at(Vector3(0, 2.5, 0))
	await wait_physics_frames(2)
	BlastDamage.apply(player, player, &"shockwave")
	assert_true(first.charged, "Una onda por encima del cuerpo entero no detona la torre")
	assert_true(second.charged)


func test_shield_armor_and_safe_zone_protect_from_blasts() -> void:
	target.reset_at(Vector3(4, 0, 0))
	target.health.spawn_shield_s = Balance.get_f("respawn.spawn_shield_s")
	BlastDamage.apply(emitter, player, &"shockwave")
	assert_eq(target.health.current, target.health.maximum)
	target.health.spawn_shield_s = 0.0
	target.health.armored = true
	BlastDamage.apply(emitter, player, &"shockwave")
	assert_eq(target.health.current, target.health.maximum)
	target.health.armored = false
	var zone: SafeZone = ZONE.instantiate()
	zone.radius = 1.0
	zone.policy = "always"
	zone.position = target.position
	arena.add_child(zone)
	BlastDamage.apply(emitter, player, &"shockwave")
	assert_eq(target.health.current, target.health.maximum, "Protege al blanco")
	zone.position = emitter.position
	BlastDamage.apply(emitter, player, &"shockwave")
	assert_eq(target.health.current, target.health.maximum, "No se emite desde la zona franca")
	zone.position = player.position
	BlastDamage.apply(emitter, player, &"shockwave")
	assert_eq(target.health.current, target.health.maximum, "Atacante en zona franca")
	var tower: FusionTower = _tower(player.position)
	assert_false(tower.trigger(), "La torre situada en zona franca no detona")
	assert_true(tower.charged)


func test_tower_hurts_triggering_runner_and_applies_edge_damage_once() -> void:
	var radius: float = Balance.get_f("hazards.fusion_tower.radius_m")
	var center: float = Balance.get_f("hazards.fusion_tower.damage_center")
	var edge: float = Balance.get_f("hazards.fusion_tower.damage_edge")
	var tower: FusionTower = _tower(Vector3.ZERO)
	player.reset_at(Vector3(2, 0, 0))
	target.reset_at(Vector3(radius, 0, 0))
	await wait_physics_frames(2)
	watch_signals(EventBus)
	assert_true(tower.trigger(player))
	assert_false(tower.trigger(player), "Una torre descargada no repite la explosion")
	assert_almost_eq(player.health.current,
			player.health.maximum - lerpf(center, edge, 2.0 / radius), 0.001)
	assert_almost_eq(target.health.current, target.health.maximum - edge, 0.001)
	assert_eq(target.health.credited_attacker(), player)
	assert_signal_emit_count(EventBus, "fusion_tower_detonated", 1)
	assert_false(tower.charged)


func test_laser_direct_hit_detonates_tower() -> void:
	var tower: FusionTower = _tower(Vector3.ZERO)
	player.reset_at(Vector3(0, 0, 12))
	await wait_physics_frames(2)
	watch_signals(EventBus)
	player.laser.tick(1.0 / Balance.get_f("weapons.laser.fire_rate_hz"), true)
	assert_false(tower.charged, "El rayo frontal alcanza el collider de la torre")
	assert_signal_emitted_with_parameters(EventBus, "fusion_tower_detonated", [tower, player])


func test_physical_contact_detonates_tower() -> void:
	var tower: FusionTower = _tower(Vector3.ZERO)
	target.reset_at(Vector3(0, 0, 4))
	await wait_physics_frames(2)
	watch_signals(EventBus)
	var collision: KinematicCollision3D = target.move_and_collide(Vector3(0, 0, -4))
	assert_not_null(collision)
	if collision != null:
		assert_eq(collision.get_collider(), tower)
	await wait_physics_frames(3)
	assert_false(tower.charged, "El area detecta el contacto sin activar manualmente la torre")
	assert_lt(target.health.current, target.health.maximum)
	assert_signal_emit_count(EventBus, "fusion_tower_detonated", 1)


func test_chain_waits_and_keeps_original_trigger_without_duplicate_blasts() -> void:
	var first: FusionTower = _tower(Vector3.ZERO)
	var second: FusionTower = _tower(Vector3(6, 0, 0))
	target.reset_at(Vector3(6, 0, 3))
	await wait_physics_frames(2)
	watch_signals(EventBus)
	assert_true(first.trigger(player))
	assert_true(second.charged)
	second.queue_chain(target)
	var delay: float = Balance.get_f("hazards.fusion_tower.chain_delay_s")
	second.tick(delay * 0.5)
	assert_true(second.charged, "La cadena espera el retraso configurado")
	second.tick(delay * 0.51)
	assert_false(second.charged)
	assert_eq(target.health.credited_attacker(), player, "No se sustituye al primer detonador")
	assert_signal_emitted_with_parameters(EventBus, "fusion_tower_detonated", [second, player])
	first.tick(delay)
	second.tick(delay)
	assert_signal_emit_count(EventBus, "fusion_tower_detonated", 2)


func test_reset_disable_pause_and_recharge_cancel_pending_chains() -> void:
	var tower: FusionTower = _tower(Vector3.ZERO)
	var delay: float = Balance.get_f("hazards.fusion_tower.chain_delay_s")
	tower.queue_chain(player)
	tower.enabled = false
	assert_false(tower.trigger(player))
	tower.enabled = true
	tower.tick(delay * 2.0)
	assert_true(tower.charged, "Deshabilitar cancela la cadena pendiente")
	tower.queue_chain(player)
	tower.reset()
	tower.tick(delay * 2.0)
	assert_true(tower.charged, "Reiniciar cancela la cadena pendiente")
	assert_true(tower.trigger(player))
	var recharge: float = Balance.get_f("hazards.fusion_tower.recharge_s")
	tower.tick(recharge * 0.5)
	assert_false(tower.charged)
	get_tree().paused = true
	tower.tick(recharge)
	get_tree().paused = false
	assert_almost_eq(tower.recharge_left, recharge * 0.5, 0.001)
	tower.tick(recharge * 0.5 + 0.01)
	assert_true(tower.charged)
	assert_eq(tower.recharge_left, 0.0)


func _runner(point: Vector3) -> Runner:
	var runner: Runner = RUNNER.instantiate()
	arena.add_child(runner)
	runner.reset_at(point)
	runner.controller = null
	runner.set_physics_process(false)
	runner.barrier.set_physics_process(false)
	return runner


func _tower(point: Vector3) -> FusionTower:
	var tower := FusionTower.new()
	tower.position = point
	arena.add_child(tower)
	tower.set_physics_process(false)
	return tower


func _box(point: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = point
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	arena.add_child(body)
	return body
