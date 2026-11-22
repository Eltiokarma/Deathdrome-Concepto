extends GutTest
## Integracion de inventario, InputFrame, combate y limpieza entre rondas.

const RUNNER := preload("res://entities/runner/runner.tscn")
const SAFE_ZONE := preload("res://entities/zones/safe_zone.tscn")
const SANDBOX := preload("res://levels/domain_01/penal_altiplano_sandbox.tscn")

var arena: Node3D
var shooter: Runner
var rival: Runner


func test_cycle_and_fire_use_the_selected_slot_through_input_frame() -> void:
	await _make_duel(Vector3(0, 0, -5))
	shooter.inventory.add(&"missile")
	shooter.inventory.add(&"shockwave")
	shooter.inventory.add(&"ram")
	var health: float = shooter.health.current
	shooter.input_frame.cycle_secondary = 1
	shooter.input_frame.secondary = true
	shooter._physics_process(1.0 / 60.0)
	shooter.input_frame = InputFrame.new()
	assert_eq(shooter.inventory.slots, [&"missile", &"ram"] as Array[StringName])
	assert_lt(rival.health.current, rival.health.maximum, "La onda seleccionada alcanza al rival")
	assert_eq(shooter.health.current, health, "La onda no causa autodaño")
	assert_eq(_projectiles().size(), 0, "Ciclar y disparar no lanza el misil anterior")
	assert_gt(shooter.secondary.cooldown_left, 0.0)


func test_cooldown_consumes_one_slot_per_valid_shot_and_preserves_unknown_weapons() -> void:
	await _make_duel()
	shooter.inventory.add(&"missile")
	shooter.inventory.add(&"missile")
	shooter.inventory.add(&"ram")
	shooter.secondary.tick(0.0, true)
	assert_eq(shooter.inventory.slots.size(), 2)
	shooter.secondary.tick(0.0, true)
	assert_eq(shooter.inventory.slots.size(), 2)
	var cooldown: float = Balance.get_f("inventory.secondary_cooldown_s")
	shooter.secondary.tick(cooldown * 0.9, true)
	assert_eq(shooter.inventory.slots.size(), 2, "Mantener el boton no salta la recarga")
	shooter.secondary.tick(cooldown * 0.2, true)
	assert_eq(shooter.inventory.slots, [&"ram"] as Array[StringName])
	assert_eq(_projectiles().size(), 2)
	shooter.secondary.tick(cooldown + 0.1, true)
	assert_eq(shooter.inventory.slots, [&"ram"] as Array[StringName])
	assert_eq(shooter.secondary.cooldown_left, 0.0, "Arma futura no consume ni inicia recarga")


func test_disabled_safe_and_destroyed_runners_cannot_spend_ammunition() -> void:
	await _make_duel()
	shooter.inventory.add(&"missile")
	shooter.set_physics_process(false)
	shooter.secondary.tick(1.0, true)
	assert_eq(shooter.inventory.slots.size(), 1)
	shooter.set_physics_process(true)
	var zone: SafeZone = SAFE_ZONE.instantiate()
	zone.radius = 5.0
	arena.add_child(zone)
	assert_true(shooter.health.in_safe_zone)
	shooter.secondary.tick(1.0, true)
	assert_eq(shooter.inventory.slots.size(), 1, "No dispara desde zona franca")
	zone.queue_free()
	await wait_physics_frames(1)
	var hit := DamageInfo.new()
	hit.type = Enums.DamageType.PURGE
	hit.weapon_id = &"purge"
	shooter.health.apply(hit)
	assert_true(shooter.health.destroyed)
	shooter.secondary.tick(1.0, true)
	assert_eq(shooter.inventory.slots.size(), 1, "Una muerte no gasta la carga restante")
	assert_eq(_projectiles().size(), 0)


func test_missile_launch_without_lock_deals_direct_damage_and_breaks_spawn_shield() -> void:
	await _make_duel()
	shooter.inventory.add(&"missile")
	shooter.health.spawn_shield_s = Balance.get_f("respawn.spawn_shield_s")
	shooter.input_frame.secondary = true
	shooter._physics_process(1.0 / 60.0)
	shooter.input_frame = InputFrame.new()
	assert_eq(shooter.inventory.slots.size(), 0)
	assert_eq(shooter.health.spawn_shield_s, 0.0)
	assert_eq(_projectiles().size(), 1)
	var projectile: MissileProjectile = _projectiles()[0]
	projectile.set_physics_process(false)
	assert_null(shooter.missile_lock.locked_target(), "No hace falta fijar para disparar recto")
	projectile.tick(1.0)
	assert_almost_eq(rival.health.current,
			rival.health.maximum - Balance.get_f("weapons.missile.damage"), 0.001)
	assert_eq(shooter.health.current, shooter.health.maximum)
	assert_eq(_projectiles().size(), 0, "El impacto retira el proyectil")


func test_switching_weapon_and_respawning_clear_missile_lock() -> void:
	await _make_duel()
	shooter.inventory.add(&"missile")
	shooter.inventory.add(&"shockwave")
	shooter.secondary.tick(shooter.stats.missile_lock_time_s + 0.01, false)
	assert_eq(shooter.missile_lock.locked_target(), rival)
	shooter.inventory.cycle(1)
	shooter.secondary.tick(0.0, false)
	assert_null(shooter.missile_lock.target)
	assert_eq(shooter.missile_lock.progress, 0.0)
	shooter.inventory.cycle(-1)
	shooter.secondary.tick(shooter.stats.missile_lock_time_s + 0.01, false)
	assert_eq(shooter.missile_lock.locked_target(), rival)
	shooter.reset_at(Vector3.ZERO)
	assert_null(shooter.missile_lock.target)
	assert_eq(shooter.missile_lock.progress, 0.0)
	assert_eq(shooter.secondary.cooldown_left, 0.0)
	assert_eq(shooter.inventory.slots.size(), 0)


func test_secondary_kills_use_normal_quota_and_score_attribution() -> void:
	await _make_duel(Vector3(0, 0, -5))
	var clock := RoundManager.new()
	arena.add_child(clock)
	clock.set_physics_process(false)
	var progress := RoundProgress.new()
	clock.add_child(progress)
	var score := RoundScore.new()
	progress.add_child(score)
	progress.register(shooter)
	progress.register(rival)
	clock.begin(1, 1)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s"))
	watch_signals(EventBus)
	for index: int in range(clock.quota):
		rival.reset_at(Vector3(0, 0, -5))
		rival.health.current = 1.0
		shooter.inventory.add(&"shockwave")
		shooter.secondary.tick(Balance.get_f("inventory.secondary_cooldown_s"), false)
		shooter.input_frame.secondary = true
		shooter._physics_process(1.0 / 60.0)
		shooter.input_frame = InputFrame.new()
		assert_true(rival.health.destroyed)
		assert_eq(progress.kills_for(shooter), index + 1)
	assert_true(progress.has_quota(shooter))
	assert_signal_emit_count(EventBus, "quota_reached", 1)
	assert_eq(score.points_for(shooter), Balance.get_i("score.kill") * clock.quota
			+ Balance.get_i("score.first_blood"))


func test_domain_results_clear_projectiles_and_new_round_recharges_towers() -> void:
	var domain: Node3D = add_child_autofree(SANDBOX.instantiate())
	var clock: RoundManager = domain.get_node("RoundManager")
	clock.set_physics_process(false)
	var runner: Runner = domain.get_node("Runner")
	var towers: Array[Node] = get_tree().get_nodes_in_group("fusion_towers")
	assert_gt(towers.size(), 0, "Las reservas T del greybox son torres reales")
	var tower: FusionTower = towers[0]
	tower.set_physics_process(false)
	domain.start_round(1)
	assert_false(tower.enabled)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s"))
	assert_true(tower.enabled)
	var point: Vector2 = domain.greybox.room_point(-20, 12)
	runner.reset_at(Vector3(point.x, 0.1, point.y))
	runner.inventory.add(&"missile")
	runner.secondary.tick(0.0, true)
	assert_eq(get_tree().get_nodes_in_group("weapon_projectiles").size(), 1)
	assert_true(tower.trigger())
	var recharge: float = Balance.get_f("hazards.fusion_tower.recharge_s")
	tower.tick(recharge - 0.1)
	assert_false(tower.charged)
	tower.tick(0.2)
	assert_true(tower.charged)
	assert_true(tower.trigger())
	clock.finish({"reason": "test_cleanup"})
	assert_eq(get_tree().get_nodes_in_group("weapon_projectiles").size(), 0)
	assert_eq(get_tree().get_nodes_in_group("weapon_effects").size(), 0)
	assert_false(tower.enabled)
	assert_eq(runner.secondary.cooldown_left, 0.0)
	domain.start_round(2)
	assert_true(tower.charged)
	assert_eq(tower.recharge_left, 0.0)
	assert_false(tower.enabled, "La introduccion no permite detonaciones")
	assert_eq(runner.inventory.slots.size(), 0)


func _make_duel(rival_position: Vector3 = Vector3(0, 0, -15)) -> void:
	arena = add_child_autofree(Node3D.new())
	shooter = RUNNER.instantiate()
	rival = RUNNER.instantiate()
	arena.add_child(shooter)
	arena.add_child(rival)
	shooter.controller = null
	rival.controller = null
	shooter.set_physics_process(false)
	rival.set_physics_process(false)
	shooter.reset_at(Vector3.ZERO)
	rival.reset_at(rival_position)
	await wait_physics_frames(2)
	shooter.set_physics_process(true)


func _projectiles() -> Array[Node]:
	return get_tree().get_nodes_in_group("weapon_projectiles")
