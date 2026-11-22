extends GutTest
## Cierre por participantes, independiente del nivel y del grupo visible de Runners.

const RUNNER := preload("res://entities/runner/runner.tscn")

var manager: RoundManager
var progress: RoundProgress
var resolution: RoundResolution
var score: RoundScore
var player: Runner
var rival: Runner
var result: Dictionary = {}


func before_each() -> void:
	result = {}
	manager = add_child_autofree(RoundManager.new())
	manager.set_physics_process(false)
	progress = RoundProgress.new()
	progress.name = "Progress"
	manager.add_child(progress)
	resolution = RoundResolution.new()
	resolution.manager_path = NodePath("..")
	resolution.progress_path = NodePath("../Progress")
	manager.add_child(resolution)
	# Conectar el puntaje despues del cierre prueba que no depende del orden de suscripcion.
	score = RoundScore.new()
	progress.add_child(score)
	player = add_child_autofree(RUNNER.instantiate())
	rival = add_child_autofree(RUNNER.instantiate())
	player.set_physics_process(false)
	rival.set_physics_process(false)
	progress.register(player)
	progress.register(rival)
	manager.begin(1, 1)
	manager.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s"))
	EventBus.round_ended.connect(_capture_result)
	watch_signals(EventBus)


func after_each() -> void:
	EventBus.round_ended.disconnect(_capture_result)


func test_escape_waits_for_other_participants_and_includes_final_score() -> void:
	_earn_quota(player, rival)
	_earn_quota(rival, player)
	EventBus.runner_escaped.emit(player, 100.0)
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.PLAYING)
	assert_eq(resolution.counts().pending, 1)
	var before: int = score.points_for(rival)
	EventBus.runner_escaped.emit(rival, 80.0)
	assert_eq(manager.state, RoundManager.State.PLAYING, "El cierre se difiere")
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.RESULTS)
	assert_eq(result.reason, "all_resolved")
	assert_eq(result.escaped, 2)
	assert_eq(result.destroyed, 0)
	var bonus: int = Balance.get_i("score.round_clear") + 80 * Balance.get_i("score.time_left_per_s")
	assert_eq(result.rival_score, before + bonus, "El resumen recibe el ultimo bonus de escape")
	EventBus.runner_escaped.emit(rival, 80.0)
	EventBus.purge_closed.emit()
	await wait_frames(1)
	assert_signal_emit_count(EventBus, "round_ended", 1)


func test_recoverable_deaths_only_become_terminal_when_purge_starts() -> void:
	_kill(player, null)
	_kill(rival, null)
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.PLAYING, "Pueden reaparecer")
	assert_eq(resolution.counts().pending, 2)
	manager.tick(manager.seconds_left)
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.RESULTS)
	assert_eq(result.destroyed, 2)
	assert_eq(result.escaped, 0)


func test_pending_ascent_remains_registered_and_outlives_purge_close() -> void:
	_earn_quota(player, rival)
	player.remove_from_group("runners")
	assert_has(progress.participants(), player, "El portal no lo borra del registro")
	manager.tick(manager.seconds_left)
	_kill(rival, null)
	EventBus.purge_closed.emit()
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.PURGE, "El ascenso aun no termino")
	assert_eq(resolution.counts().pending, 1)
	EventBus.runner_escaped.emit(player, 0.0)
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.RESULTS)
	assert_eq(result.escaped, 1)
	assert_eq(result.destroyed, 1)


func test_invalid_escape_events_cannot_resolve_a_participant() -> void:
	EventBus.runner_escaped.emit(player, 10.0)
	assert_false(resolution.has_escaped(player), "Sin cuota")
	_earn_quota(player, rival)
	for invalid: float in [NAN, INF, -1.0, Balance.get_f("round.duration_s") + 1.0]:
		EventBus.runner_escaped.emit(player, invalid)
	assert_false(resolution.has_escaped(player), "Reloj invalido")
	_kill(player, null)
	EventBus.runner_escaped.emit(player, 10.0)
	assert_false(resolution.has_escaped(player), "Destruido")
	await wait_frames(1)
	assert_signal_emit_count(EventBus, "round_ended", 0)


func test_new_round_clears_resolution_and_ignores_old_deferred_evaluation() -> void:
	_earn_quota(player, rival)
	EventBus.runner_escaped.emit(player, 10.0)
	manager.finish({"reason": "restart"})
	player.reset_at(Vector3.ZERO)
	rival.reset_at(Vector3.RIGHT * 5.0)
	manager.begin(1, 2)
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.INTRO)
	assert_false(resolution.has_escaped(player))
	assert_eq(resolution.counts().pending, 2)
	assert_eq(progress.kills_for(player), 0)
	assert_gt(score.points_for(player), 0, "El puntaje de sesion se conserva")


func test_removed_participants_are_not_returned_and_empty_round_does_not_finish() -> void:
	player.queue_free()
	rival.queue_free()
	assert_eq(progress.participants().size(), 0)
	manager.tick(manager.seconds_left)
	await wait_frames(1)
	assert_eq(manager.state, RoundManager.State.PURGE, "Sin participantes no se inventa un resultado")
	assert_signal_emit_count(EventBus, "round_ended", 0)


func _earn_quota(winner: Runner, victim: Runner) -> void:
	for _kill_index: int in range(manager.quota):
		_kill(victim, winner)
		victim.reset_at(Vector3.RIGHT * 5.0)


func _kill(victim: Runner, killer: Runner) -> void:
	var hit := DamageInfo.new()
	hit.type = Enums.DamageType.BARRIER
	hit.source = killer
	hit.weapon_id = &"barrier"
	victim.health.apply(hit)


func _capture_result(snapshot: Dictionary) -> void:
	result = snapshot.duplicate(true)
	result["rival_score"] = score.points_for(rival)
