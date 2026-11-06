extends GutTest
## PUR-032 (AreaTracker), PUR-036 (compuertas por ronda) y PUR-034 (Purga por salas) sobre el
## greybox oficial del Penal Altiplano.

const SANDBOX := preload("res://levels/domain_01/penal_altiplano_sandbox.tscn")
const RUNNER := preload("res://entities/runner/runner.tscn")

var sandbox: Node3D
var greybox: PenalAltiplanoGreybox
var tracker: AreaTracker
var purge: DomainPurgeField
var clock: RoundManager
var runner: Runner


func before_each() -> void:
	sandbox = add_child_autofree(SANDBOX.instantiate())
	greybox = sandbox.get_node("Greybox")
	tracker = sandbox.get_node("AreaTracker")
	purge = sandbox.get_node("DomainPurgeField")
	clock = sandbox.get_node("RoundManager")
	runner = sandbox.get_node("Runner")
	runner.set_physics_process(false)
	tracker.set_physics_process(false)
	await wait_physics_frames(2)


func test_area_changes_once_per_threshold_without_flicker() -> void:
	var axis: Vector3 = greybox.GATES[1]
	_place(Vector3(0, 0, 10))
	tracker.refresh()
	assert_eq(tracker.area_of(runner), 0)
	watch_signals(EventBus)
	# Oscila a ±0.5 m del umbral hub ↔ conexión: no cambia de área.
	for step: int in range(20):
		var offset: float = 0.5 if step % 2 == 0 else -0.5
		_place(axis * (greybox.hub_radius + offset))
		tracker.refresh()
	assert_signal_emit_count(EventBus, "area_changed", 0)
	_place(axis * (greybox.hub_radius + 1.5))
	tracker.refresh()
	assert_eq(tracker.area_of(runner), 1)
	_place(axis * (greybox.corridor_end + 50.0))
	tracker.refresh()
	assert_signal_emit_count(EventBus, "area_changed", 1, "Conexión y sala son la misma área")
	_place(axis * (greybox.hub_radius - 0.5))
	tracker.refresh()
	assert_eq(tracker.area_of(runner), 1, "Medio metro dentro del hub aún no cuenta")
	_place(axis * (greybox.hub_radius - 1.5))
	tracker.refresh()
	assert_eq(tracker.area_of(runner), 0)
	assert_signal_emit_count(EventBus, "area_changed", 2)


func test_area_at_covers_every_room_and_rejects_outside() -> void:
	for gate: int in greybox.GATES:
		var point: Vector2 = greybox.room_point(0, 100, gate)
		assert_eq(greybox.area_at(Vector3(point.x, 0, point.y)), gate)
		var corridor: Vector2 = greybox.corridor_point(gate, 0, 40)
		assert_eq(greybox.area_at(Vector3(corridor.x, 0, corridor.y)), gate)
	assert_eq(greybox.area_at(Vector3(100, 0, 100)), -1, "Entre conexiones, fuera del nivel")


func test_gates_follow_open_areas_by_round() -> void:
	var expected := {1: [1, 2], 2: [1, 2, 3], 3: [1, 2, 3, 4]}
	for round_index: int in expected:
		sandbox.start_round(round_index)
		await wait_physics_frames(2)
		for gate: int in range(1, 5):
			var open: bool = gate in expected[round_index]
			assert_eq(greybox.is_gate_open(gate), open, "R%d compuerta %d" % [round_index, gate])
			var slab: StaticBody3D = greybox.get_node("Gate%d" % gate)
			assert_eq(slab.get_node("RedLight").is_visible_in_tree(), not open, "Luz roja")
			var axis: Vector3 = greybox.GATES[gate]
			var from: Vector3 = axis * (greybox.hub_radius - 3.0) + Vector3.UP
			var to: Vector3 = axis * (greybox.hub_radius + 3.0) + Vector3.UP
			var query := PhysicsRayQueryParameters3D.create(from, to, 1)
			var blocked: bool = not greybox.get_world_3d().direct_space_state.intersect_ray(
					query).is_empty()
			assert_eq(blocked, not open, "Paso físico por la compuerta %d" % gate)


func test_room_fronts_advance_then_hub_closes_and_covers_everything() -> void:
	_enter_purge(1)
	purge.set_physics_process(false)
	var speed: float = Balance.get_f("purge.speed_mps")
	var axis: Vector3 = greybox.GATES[1]
	var deep: Vector3 = axis * (greybox.area_far_edge() - 5.0)
	assert_false(purge.contains(deep), "El frente nace en el muro de fondo")
	purge.tick(4.0 / speed)
	assert_false(purge.contains(deep))
	purge.tick(2.0 / speed)
	assert_true(purge.contains(deep), "Tras 6 m, el punto a 5 m del fondo está purgado")
	var closed_room: Vector2 = greybox.room_point(0, 100, 3)
	assert_true(purge.contains(Vector3(closed_room.x, 0, closed_room.y)),
			"Sala cerrada en R1: letal desde el inicio, sin refugio")
	var hub_point := Vector3(0, 0, greybox.hub_radius - 3.0)
	purge.tick(purge.max_travel() / speed - 1.0)
	assert_false(purge.contains(hub_point), "El hub resiste hasta que llegan los frentes")
	assert_almost_eq(purge.front_along(), greybox.hub_radius + speed - 6.0, 0.01)
	watch_signals(EventBus)
	purge.tick(1.0 + Balance.get_f("purge.hub_close_s") * 0.5)
	assert_true(purge.contains(hub_point), "El cierre del hub alcanza el anillo exterior")
	assert_false(purge.contains(Vector3(1, 0, 1)), "El centro cae al final")
	purge.tick(Balance.get_f("purge.hub_close_s"))
	purge._physics_process(0.0)
	purge._physics_process(0.0)
	assert_signal_emit_count(EventBus, "purge_closed", 1)
	var reach: float = greybox.area_far_edge()
	var uncovered: int = 0
	for x: float in range(-int(reach), int(reach), 8):
		for z: float in range(-int(reach), int(reach), 8):
			var point := Vector3(x, 0, z)
			if greybox.area_at(point) >= 0 and not purge.contains(point):
				uncovered += 1
	assert_eq(uncovered, 0, "La Purga cubre el 100 % del volumen jugable")


func test_purge_kills_runner_left_in_room_and_spares_escapee() -> void:
	var straggler: Runner = RUNNER.instantiate()
	sandbox.add_child(straggler)
	straggler.set_physics_process(false)
	var deep: Vector2 = greybox.room_point(0, 200)
	straggler.global_position = Vector3(deep.x, 0.1, deep.y)
	runner.set_physics_process(true)
	sandbox.start_purge_preview()
	for _second: int in range(30):
		await wait_physics_frames(60)
		if sandbox.route_finished:
			break
	# El ascenso por el portal dura `portal.ascent_s` después de llegar al podio.
	await wait_physics_frames(ceili((Balance.get_f("portal.ascent_s") + 0.5) * 60.0))
	gut.p("Huida: %s" % sandbox.route_events)
	assert_true(sandbox.route_finished, "La huida llega al portal: %s" % sandbox.route_events)
	assert_false(runner.health.destroyed, "Quien huye a tiempo sobrevive al frente")
	assert_true(sandbox.route_events.has("escapa por el portal"), "Con cuota, el portal lo saca")
	assert_true(straggler.health.destroyed, "Quien se queda en la sala muere")


func test_quota_opens_portal_and_escape_scores() -> void:
	runner.set_physics_process(true)
	sandbox.start_quota_preview()
	var portal: RoundPortal = sandbox.get_node("Portal")
	assert_false(portal.eligible(runner), "Sin cuota el portal está cerrado")
	assert_eq(clock.state, RoundManager.State.PLAYING)
	watch_signals(EventBus)
	for _second: int in range(60):
		await wait_physics_frames(60)
		if sandbox.route_events.has("escapa por el portal"):
			break
	gut.p("Caza: %s" % sandbox.route_events)
	var progress: RoundProgress = sandbox.get_node("RoundManager/RoundProgress")
	assert_eq(progress.kills_for(runner), clock.quota, "Dos bajas atribuidas = cuota de R1")
	assert_signal_emitted(EventBus, "quota_reached")
	assert_true(sandbox.route_events.has("escapa por el portal"), "%s" % sandbox.route_events)
	var score: RoundScore = sandbox.get_node("RoundManager/RoundProgress/RoundScore")
	var expected: int = Balance.get_i("score.kill") * clock.quota
	assert_gt(score.points_for(runner), expected, "Bajas + primera sangre + escape con tiempo")


func _enter_purge(round_index: int) -> void:
	sandbox.start_round(round_index)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s")
			+ Balance.get_f("round.duration_s") + 0.001)
	assert_eq(clock.state, RoundManager.State.PURGE)


func _place(point: Vector3) -> void:
	runner.global_position = point + Vector3.UP * 0.1


func test_strafe_kills_targets_while_moving_and_meets_round_two_quota() -> void:
	runner.set_physics_process(true)
	sandbox.start_strafe_preview()
	assert_eq(clock.quota, 3, "Cuota de la ronda 2 en el Dominio 1")
	for _second: int in range(70):
		await wait_physics_frames(60)
		if sandbox.route_events.has("escapa por el portal"):
			break
	var events: Dictionary = sandbox.route_events
	gut.p("Tiro en marcha: %s" % events)
	assert_gte(events.get("bajas en marcha", 0), 3, "Las tres bajas, disparando en marcha")
	var progress: RoundProgress = sandbox.get_node("RoundManager/RoundProgress")
	assert_eq(progress.kills_for(runner), 3)
	assert_true(events.has("escapa por el portal"), "%s" % events)
