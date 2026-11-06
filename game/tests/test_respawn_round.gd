extends GutTest
## PUR-023 (muerte, pira y piloto) y PUR-024 (reaparición y escudo) en la escena del Dominio 1.

const SANDBOX := preload("res://levels/domain_01/penal_altiplano_sandbox.tscn")

var sandbox: Node3D
var greybox: PenalAltiplanoGreybox
var clock: RoundManager
var progress: RoundProgress
var score: RoundScore
var runner: Runner


func before_each() -> void:
	sandbox = add_child_autofree(SANDBOX.instantiate())
	greybox = sandbox.get_node("Greybox")
	clock = sandbox.get_node("RoundManager")
	progress = sandbox.get_node("RoundManager/RoundProgress")
	score = sandbox.get_node("RoundManager/RoundProgress/RoundScore")
	runner = sandbox.get_node("Runner")
	await wait_physics_frames(2)


func test_death_pyre_pilot_mercy_and_delayed_respawn() -> void:
	sandbox.start_death_preview()
	var gunner: Runner = sandbox.get_node("Gunner")
	watch_signals(EventBus)
	await _wait_for("reaparece", 20)
	var events: Dictionary = sandbox.route_events
	gut.p("Muerte: %s" % events)
	assert_true(events.has("muere") and events.has("piloto rematado"), "%s" % events)
	assert_signal_emitted(EventBus, "pilot_ejected")
	var delay: float = (Balance.get_f("respawn.delay_s")
			+ Balance.get_f("respawn.mercy_kill_extra_s"))
	assert_almost_eq(events.get("reaparece", INF) - events.muere, delay, 0.05,
			"Reaparece a los 4 s + 2 s por mercy kill")
	assert_lt(events["piloto rematado"] - events.muere, Balance.get_f("death.pilot_window_s"))
	assert_eq(greybox.area_at(runner.global_position), 0, "Reaparece en el Área 0")
	assert_almost_eq(runner.health.current, runner.health.maximum, 0.001, "Integridad llena")
	assert_almost_eq(runner.barrier.energy, runner.stats.barrier_energy, 0.001, "Barrera llena")
	# El evento se consulta cada segundo: el escudo ya ha corrido como mucho 1 s.
	assert_between(runner.health.spawn_shield_s, Balance.get_f("respawn.spawn_shield_s") - 1.05,
			Balance.get_f("respawn.spawn_shield_s"), "Escudo de aparición activo")
	assert_eq(progress.kills_for(gunner), 1, "El mercy kill no suma a la cuota")
	var expected: int = (Balance.get_i("score.kill") + Balance.get_i("score.first_blood")
			+ Balance.get_i("score.mercy_kill"))
	assert_eq(score.points_for(gunner), expected, "Baja + primera sangre + mercy kill")


func test_pyre_lasts_and_pilot_flees_then_is_picked_up() -> void:
	_start_playing()
	var killer: Runner = sandbox.spawn_targets([Vector2(0, 60)])[0]
	var spot: Vector2 = greybox.room_point(0, 30)
	runner.reset_at(Vector3(spot.x, 0.1, spot.y), 0.0)
	_kill(runner, killer)
	await wait_physics_frames(2)
	var pilots: Array[Node] = get_tree().get_nodes_in_group("pilots")
	assert_eq(pilots.size(), 1)
	var pilot: Pilot = pilots[0]
	assert_eq(pilot.integrity, Balance.get_f("death.pilot_integrity"))
	var start: Vector3 = pilot.global_position
	await wait_physics_frames(60)
	var moved: float = Vector2(pilot.global_position.x - start.x,
			pilot.global_position.z - start.z).length()
	assert_almost_eq(moved, Balance.get_f("death.pilot_speed_mps"), 0.5, "Huye a 6 m/s")
	assert_gt(pilot.global_position.distance_to(killer.global_position),
			start.distance_to(killer.global_position), "Huye alejándose del atacante")
	await wait_physics_frames(roundi(Balance.get_f("death.pilot_window_s") * 60.0))
	assert_eq(get_tree().get_nodes_in_group("pilots").size(), 0, "Recogido tras 2.5 s")
	assert_eq(get_tree().get_nodes_in_group("pyres").size(), 1, "La pira sigue")
	var respawner: RoundRespawner = sandbox.get_node("RoundRespawner")
	var elapsed: int = 2 + 60 + roundi(Balance.get_f("death.pilot_window_s") * 60.0)
	var respawn_frame: int = roundi(Balance.get_f("respawn.delay_s") * 60.0)
	await wait_physics_frames(respawn_frame - elapsed - 10)
	assert_true(runner.health.destroyed, "Sin mercy kill, aún no han pasado 4 s")
	await wait_physics_frames(20)
	assert_false(runner.health.destroyed, "Reaparece a los 4 s sin mercy kill")
	assert_eq(respawner.pending.size(), 0)
	await wait_physics_frames(roundi(Balance.get_f("death.pyre_s") * 60.0) - respawn_frame)
	assert_eq(get_tree().get_nodes_in_group("pyres").size(), 0, "La pira dura 6 s")


func test_spawn_shield_breaks_when_firing() -> void:
	_start_playing()
	_move_to_room()
	_kill(runner, null)
	await wait_physics_frames(roundi((Balance.get_f("respawn.delay_s") + 0.2) * 60.0))
	assert_false(runner.health.destroyed)
	assert_gt(runner.health.spawn_shield_s, 0.0)
	var spot: Vector2 = greybox.room_point(0, 30)
	runner.global_position = Vector3(spot.x, 0.1, spot.y)
	runner.controller = null
	runner.input_frame.laser = true
	await wait_physics_frames(3)
	assert_eq(runner.health.spawn_shield_s, 0.0, "Disparar cancela el escudo")


func test_no_respawn_during_purge_and_round_start_restores() -> void:
	_start_playing()
	clock.tick(Balance.get_f("round.duration_s") + 0.001)
	assert_eq(clock.state, RoundManager.State.PURGE)
	_move_to_room()
	_kill(runner, null)
	await wait_physics_frames(roundi((Balance.get_f("respawn.delay_s") + 3.0) * 60.0))
	assert_true(runner.health.destroyed, "Sin reaparición durante la Purga")
	clock.finish({"reason": "test"})
	sandbox.start_round(2)
	assert_false(runner.health.destroyed, "La ronda siguiente empieza con todos en pie")
	assert_eq(greybox.area_at(runner.global_position), 0)


func _start_playing() -> void:
	sandbox.start_round(1)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s") + 0.001)
	assert_eq(clock.state, RoundManager.State.PLAYING)


## El hub es zona franca (bloquea el daño): las muertes de prueba ocurren en la sala 1.
func _move_to_room() -> void:
	var spot: Vector2 = greybox.room_point(0, 30)
	runner.global_position = Vector3(spot.x, 0.1, spot.y)


func _kill(victim: Runner, killer: Runner) -> void:
	var hit := DamageInfo.new()
	hit.type = Enums.DamageType.BARRIER
	hit.source = killer
	hit.weapon_id = &"barrier"
	victim.health.apply(hit)


func _wait_for(event: String, seconds: int) -> void:
	for _second: int in range(seconds):
		await wait_physics_frames(60)
		if sandbox.route_events.has(event):
			return
