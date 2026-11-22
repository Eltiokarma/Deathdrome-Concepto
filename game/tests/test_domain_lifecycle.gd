extends GutTest
## Integracion del ciclo completo en el Penal Altiplano, sin adelantar minutos de fisica.

const SANDBOX := preload("res://levels/domain_01/penal_altiplano_sandbox.tscn")

var sandbox: Node3D
var clock: RoundManager
var progress: RoundProgress
var score: RoundScore
var runner: Runner
var portal: RoundPortal
var purge: DomainPurgeField
var resolution: RoundResolution


func before_each() -> void:
	sandbox = add_child_autofree(SANDBOX.instantiate())
	clock = sandbox.get_node("RoundManager")
	progress = sandbox.get_node("RoundManager/RoundProgress")
	score = progress.get_node("RoundScore")
	runner = sandbox.get_node("Runner")
	portal = sandbox.get_node("Portal")
	purge = sandbox.get_node("DomainPurgeField")
	resolution = sandbox.get_node("RoundResolution")
	clock.set_physics_process(false)
	portal.set_physics_process(false)
	purge.set_physics_process(false)
	sandbox.get_node("RoundRespawner").set_physics_process(false)
	await wait_physics_frames(2)


func test_intro_and_countdown_freeze_participants_and_pickups() -> void:
	var rival: Runner = sandbox.spawn_targets([Vector2(20, 30)])[0]
	sandbox.start_round(1)
	var initial: Vector3 = runner.global_position
	var pickup: Pickup = _weapon_pickup()
	runner.input_frame.throttle = 1.0
	runner.input_frame.laser = true
	rival.input_frame.barrier = true
	assert_false(runner.is_physics_processing())
	assert_false(rival.is_physics_processing())
	assert_false(pickup.try_collect(runner), "No se recoge durante la introduccion")
	await wait_physics_frames(2)
	assert_eq(runner.global_position, initial)
	clock.tick(Balance.get_f("round.intro_s"))
	assert_eq(clock.state, RoundManager.State.COUNTDOWN)
	assert_false(runner.is_physics_processing())
	assert_false(rival.is_physics_processing())
	clock.tick(Balance.get_f("round.countdown_s"))
	assert_eq(clock.state, RoundManager.State.PLAYING)
	assert_true(runner.is_physics_processing())
	assert_true(rival.is_physics_processing())
	assert_true(pickup.try_collect(runner), "Se habilita al empezar el juego")


func test_targets_registered_during_intro_also_wait_for_playing() -> void:
	sandbox.start_round(1)
	var rival: Runner = sandbox.spawn_targets([Vector2(20, 30)])[0]
	assert_false(rival.is_physics_processing(), "Un blanco nuevo respeta la fase actual")
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s"))
	assert_true(rival.is_physics_processing())


func test_new_round_restores_living_destroyed_and_escaped_participants() -> void:
	_start_playing()
	var targets: Array[Runner] = sandbox.spawn_targets([Vector2(20, 30), Vector2(-20, 30)])
	var fallen: Runner = targets[0]
	var survivor: Runner = targets[1]
	_move_to_room(runner)
	_earn_quota(runner, fallen)
	_kill(fallen, runner)
	var hit := DamageInfo.new()
	hit.type = Enums.DamageType.LASER
	hit.source = runner
	hit.amount = 10.0
	survivor.health.apply(hit)
	assert_lt(survivor.health.current, survivor.health.maximum)
	var pickup: Pickup = _weapon_pickup()
	assert_true(pickup.try_collect(runner))
	for participant: Runner in [fallen, survivor]:
		participant.inventory.add(&"missile")
	survivor.barrier.tick(0.2, true)
	runner.global_position = portal.global_position
	portal._on_entered(runner)
	portal.tick(Balance.get_f("portal.ascent_s"))
	await wait_physics_frames(2)
	assert_true(resolution.has_escaped(runner))
	assert_false(runner.is_in_group("runners"))
	assert_true(fallen.health.destroyed)
	assert_eq(clock.state, RoundManager.State.PLAYING)
	var previous_score: int = score.points_for(runner)
	assert_gt(previous_score, 0)
	sandbox.start_round(2)
	assert_eq(clock.state, RoundManager.State.INTRO)
	var positions: Array[Vector3] = []
	for participant: Runner in progress.participants():
		assert_false(participant.health.destroyed)
		assert_eq(participant.health.current, participant.health.maximum)
		assert_eq(participant.barrier.energy, participant.stats.barrier_energy)
		assert_eq(participant.inventory.slots.size(), 0)
		assert_true(participant.is_in_group("runners"))
		assert_true(participant.get_collision_layer_value(2))
		assert_false(participant.is_physics_processing())
		assert_eq(sandbox.greybox.area_at(participant.global_position), 0)
		assert_false(positions.has(participant.global_position), "Spawn distinto por participante")
		positions.append(participant.global_position)
	assert_eq(score.points_for(runner), previous_score)
	assert_eq(progress.kills_for(runner), 0)
	assert_false(resolution.has_escaped(runner))
	assert_false(sandbox._escaped)
	assert_true(sandbox._route.is_empty())
	assert_eq(runner.controller, runner.get_node("PlayerInput"))
	assert_true(pickup.available)
	assert_eq(pickup.respawn_left, 0.0)
	assert_true(sandbox.greybox.is_gate_open(3))
	assert_false(sandbox.greybox.is_gate_open(4))
	assert_eq(get_tree().get_nodes_in_group("pilots").size(), 0)
	assert_eq(get_tree().get_nodes_in_group("pyres").size(), 0)
	assert_true(runner.get_node("RunnerCamera/SpringArm3D/Camera3D").current)


func test_recovery_key_cannot_revive_or_evade_purge() -> void:
	_start_playing()
	_move_to_room(runner)
	_kill(runner, null)
	var life: int = runner.health.life_id
	_reset_key()
	assert_true(runner.health.destroyed, "R no evita la espera de reaparicion")
	assert_eq(runner.health.life_id, life)
	sandbox.start_round(1)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s"))
	_move_to_room(runner)
	clock.tick(clock.seconds_left)
	var position: Vector3 = runner.global_position
	_reset_key()
	assert_eq(runner.global_position, position, "R no teletransporta fuera del frente")
	_kill(runner, null)
	life = runner.health.life_id
	_reset_key()
	assert_true(runner.health.destroyed, "R no revive durante la Purga")
	assert_eq(runner.health.life_id, life)
	await wait_frames(1)
	assert_eq(clock.state, RoundManager.State.RESULTS)
	_reset_key()
	assert_eq(runner.health.life_id, life, "Resultados tampoco permite recuperarse")


func test_escape_clears_fade_waits_for_rival_and_finishes_after_purge() -> void:
	_start_playing()
	var rival: Runner = sandbox.spawn_targets([Vector2(20, 30)])[0]
	_move_to_room(runner)
	_earn_quota(runner, rival)
	runner.global_position = portal.global_position
	portal._on_entered(runner)
	portal.tick(Balance.get_f("portal.ascent_s") * 0.8)
	assert_true(portal.is_ascending(runner))
	var position: Vector3 = runner.global_position
	_reset_key()
	assert_eq(runner.global_position, position, "R no interrumpe el ascenso")
	portal.tick(Balance.get_f("portal.ascent_s"))
	await wait_physics_frames(2)
	assert_eq(clock.state, RoundManager.State.PLAYING, "El rival todavia juega")
	assert_eq(portal.get_node("Overlay/Fade").color.a, 0.0)
	assert_true(sandbox.overview.current)
	assert_false(runner.is_in_group("runners"))
	assert_false(runner.is_physics_processing())
	sandbox._process(0.0)
	assert_string_contains(sandbox.status.text, "QUEDAN 1 PARTICIPANTES")
	watch_signals(EventBus)
	clock.tick(clock.seconds_left)
	var duration: float = purge.max_travel() / Balance.get_f("purge.speed_mps")
	purge.tick(duration + Balance.get_f("purge.hub_close_s") + 0.1)
	await wait_frames(1)
	assert_true(rival.health.destroyed)
	assert_false(runner.health.destroyed)
	assert_eq(clock.state, RoundManager.State.RESULTS)
	assert_eq(resolution.counts().escaped, 1)
	assert_eq(resolution.counts().destroyed, 1)
	assert_false(rival.is_physics_processing())
	assert_eq(portal.get_node("Overlay/Fade").color.a, 0.0)
	assert_false(rival.model.visible, "La ultima muerte se presenta antes de congelar")
	assert_false(rival.get_collision_layer_value(2))
	sandbox._process(0.0)
	assert_string_contains(sandbox.status.text, "RESULTADOS")
	assert_string_contains(sandbox.status.text, "ESCAPASTE")
	purge.tick(1.0)
	await wait_frames(1)
	assert_signal_emit_count(EventBus, "round_ended", 1)


func test_results_remove_active_barriers_and_disable_collection() -> void:
	_start_playing()
	_move_to_room(runner)
	var start: Vector3 = runner.global_position
	var segment: BarrierSegment = runner.barrier.emit_segment(start, start + Vector3.RIGHT * 2.0)
	assert_not_null(segment)
	assert_gt(segment.remaining, 0.0)
	clock.finish({"reason": "sandbox_restart"})
	assert_false(runner.is_physics_processing())
	assert_eq(segment.remaining, 0.0, "No queda dano de barreras en resultados")
	assert_false(_weapon_pickup().try_collect(runner))


func _start_playing() -> void:
	sandbox.start_round(1)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s"))


func _move_to_room(participant: Runner) -> void:
	var point: Vector2 = sandbox.greybox.room_point(20, 30)
	participant.reset_at(Vector3(point.x, 0.1, point.y))


func _earn_quota(winner: Runner, victim: Runner) -> void:
	for _kill_index: int in range(clock.quota):
		_kill(victim, winner)
		_move_to_room(victim)


func _kill(victim: Runner, killer: Runner) -> void:
	var hit := DamageInfo.new()
	hit.type = Enums.DamageType.BARRIER
	hit.source = killer
	hit.weapon_id = &"barrier"
	victim.health.apply(hit)


func _reset_key() -> void:
	var event := InputEventAction.new()
	event.action = &"reset_runner"
	event.pressed = true
	sandbox._unhandled_input(event)


func _weapon_pickup() -> Pickup:
	for pickup: Pickup in get_tree().get_nodes_in_group("pickups"):
		if sandbox.is_ancestor_of(pickup) and pickup.kind == &"weapon":
			return pickup
	return null
