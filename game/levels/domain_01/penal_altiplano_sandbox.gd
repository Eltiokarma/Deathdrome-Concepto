extends Node3D
## Banco del greybox hub + sala 1. Piloto automático y vista aérea son herramientas de revisión.
## Argumentos: --overview-preview (vista aérea sin techos), --route-a/b/2/3/4 (piloto),
## --round=N (ronda N con compuertas, reloj, Purga, portal y cuota), --quota-preview (caza de
## dos blancos y ascenso por el portal), --purge-preview (huida de la Purga hasta el portal).

## Ruta A (alta) y B (suelo) de la ficha, como puntos de paso en X/Z del mundo.
const ROUTES := {
	"a": [
		Vector2(2, -24), Vector2(-2, -34), Vector2(-14, -43), Vector2(-14, -50),
		Vector2(-14, -60), Vector2(-7, -65), Vector2(13, -66.5), Vector2(14, -56),
		Vector2(14, -45), Vector2(3, -38), Vector2(0, -26), Vector2(0, -12), Vector2(0, -2),
	],
	"b": [
		Vector2(-2, -24), Vector2(2, -34), Vector2(14, -43), Vector2(13, -50), Vector2(5, -53),
		Vector2(-6, -54), Vector2(-9, -46), Vector2(-14, -43), Vector2(-3, -36),
		Vector2(0, -26), Vector2(0, -12), Vector2(0, -2),
	],
}
## Variante grande: tramo dentro de la sala en coordenadas locales (u, d); la entrada y la
## vuelta por conexión y hub reutilizan los puntos de la ruta normal.
const LARGE_ROUTES := {
	"a": [
		Vector2(-20, 5), Vector2(-102, 10), Vector2(-102, 30), Vector2(-102, 120),
		Vector2(-100, 208), Vector2(-40, 210), Vector2(-40, 190), Vector2(0, 160),
		Vector2(0, 146), Vector2(0, 114), Vector2(0, 88), Vector2(0, 30), Vector2(14, 16),
		Vector2(3, 3),
	],
	"b": [
		Vector2(20, 5), Vector2(14, 20), Vector2(14, 84), Vector2(35, 92), Vector2(40, 114),
		Vector2(40, 138),
		Vector2(56, 146), Vector2(56, 162), Vector2(56, 178), Vector2(16, 178),
		Vector2(0, 160), Vector2(0, 146), Vector2(-36, 140), Vector2(-36, 90),
		Vector2(-14, 80), Vector2(-14, 12), Vector2(-3, 3),
	],
	# Taller: sube al anillo, recorre su lado oeste, cae al centro y vuelve por el este.
	"2": [
		Vector2(-20, 5), Vector2(-26, 20), Vector2(-33, 34), Vector2(-33, 48), Vector2(-45, 55),
		Vector2(-54, 66), Vector2(-54, 95), Vector2(-40, 104), Vector2(0, 110), Vector2(0, 150),
		Vector2(0, 172),
		Vector2(20, 186), Vector2(45, 186), Vector2(70, 180), Vector2(75, 150), Vector2(75, 70),
		Vector2(70, 36), Vector2(20, 36), Vector2(14, 16), Vector2(12, 5), Vector2(2, 2),
	],
	# Galería: plataforma oeste, galería central y canal este.
	"3": [
		Vector2(-20, 5), Vector2(-50, 30), Vector2(-70, 40), Vector2(-70, 70), Vector2(-70, 136),
		Vector2(-45, 136), Vector2(-25, 136), Vector2(-25, 150), Vector2(8, 148),
		Vector2(8, 172), Vector2(56, 172), Vector2(94, 168), Vector2(104, 150),
		Vector2(104, 62), Vector2(90, 40), Vector2(30, 30), Vector2(14, 16), Vector2(12, 5),
		Vector2(2, 2),
	],
	# Patio de vigilancia: patio sureste, torre central, patio noroeste y portón oeste.
	"4": [
		Vector2(20, 5), Vector2(14, 20), Vector2(14, 60), Vector2(14, 70), Vector2(4, 82),
		Vector2(0, 90), Vector2(0, 108), Vector2(0, 128), Vector2(0, 134), Vector2(-14, 138),
		Vector2(-35, 165), Vector2(-60, 160), Vector2(-92, 125), Vector2(-92, 95),
		Vector2(-60, 60), Vector2(-60, 40), Vector2(-30, 16), Vector2(-12, 5), Vector2(-2, 2),
	],
}
## Huida de la Purga desde el fondo de la sala 1 hasta el portal (coordenadas locales).
const ESCAPE_START := Vector2(10, 195)
const ESCAPE_ROUTE := [
	Vector2(8, 160), Vector2(4, 150), Vector2(28, 140), Vector2(28, 84), Vector2(28, 40),
	Vector2(14, 16), Vector2(12, 5), Vector2(2, 2),
]
## Caza de prueba: el piloto se detiene en HUNT_POINT y derriba los blancos con el láser.
const HUNT_POINT := Vector2(-20, 12)
const QUOTA_TARGETS := [Vector2(-45, 30), Vector2(40, 30)]
const RUNNER_SCENE := preload("res://entities/runner/runner.tscn")
const AIM_TOLERANCE_DEG := 8.0
const ARRIVE_M := 3.0
## Distancia al centro donde termina una ruta de exploración: rampa del podio, junto al portal.
const PORTAL_FOOT_M := 7.5
const CORNER_LOOKAHEAD_M := 10.0
const CORNER_SPEED_MPS := 14.0

var route_events: Dictionary = {}
var route_finished: bool = false
var _route: Array = []
var _route_name: String = ""
var _waypoint: int = 0
var _time: float = 0.0
var _wall_hits: int = 0
var _was_on_wall: bool = false
var _overview_angle: float = 0.6
var _gate: int = 1
var _escaped: bool = false
var _hunt_at: int = -1
var _hunting: bool = false
var _prey: Array[Runner] = []
@onready var greybox: PenalAltiplanoGreybox = $Greybox
@onready var runner: Runner = $Runner
@onready var overview: Camera3D = $Overview
@onready var clock: RoundManager = $RoundManager
@onready var tracker: AreaTracker = $AreaTracker
@onready var purge: DomainPurgeField = $DomainPurgeField
@onready var status: Label = $UI/Status
@onready var progress: RoundProgress = $RoundManager/RoundProgress
@onready var score: RoundScore = $RoundManager/RoundProgress/RoundScore
@onready var portal: RoundPortal = $Portal


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	$SafeZone.radius = greybox.hub_radius
	progress.register(runner)
	EventBus.runner_escaped.connect(_on_escaped)
	_reset_runner()
	if "--overview-preview" in args:
		greybox.set_ceilings_visible(false)
		overview.make_current()
		runner.controller = null
		if "--purge-preview" in args:
			start_purge_preview()
		return
	for key: String in LARGE_ROUTES:
		if "--route-" + key in args:
			start_route(key)
	for arg: String in args:
		if arg.begins_with("--round="):
			start_round(arg.get_slice("=", 1).to_int())
	if "--purge-preview" in args:
		start_purge_preview()
	if "--quota-preview" in args:
		start_quota_preview()
	runner.get_node("RunnerCamera/SpringArm3D/Camera3D").make_current()


## Ronda de prueba: compuertas por ronda, reloj, Purga, portal y cuota del dominio.
func start_round(round_index: int) -> void:
	if clock.state in [RoundManager.State.INTRO, RoundManager.State.COUNTDOWN]:
		# RoundManager solo termina rondas en juego: se adelanta la intro antes de reiniciar.
		var countdown: float = Balance.get_f("round.countdown_s")
		clock.tick(clock.phase_left + (countdown if clock.state == RoundManager.State.INTRO
				else 0.0) + 0.001)
	if clock.state not in [RoundManager.State.LOADING, RoundManager.State.RESULTS]:
		clock.finish({"reason": "sandbox_restart"})
	clock.begin(1, round_index)


## Coloca al Runner al fondo de la sala 1 con el reloj a punto de terminar; al empezar la
## Purga, el piloto automático huye hacia el portal por delante del frente.
func start_purge_preview() -> void:
	start_round(1)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s")
			+ Balance.get_f("round.duration_s") - 3.0)
	var start: Vector2 = greybox.room_point(ESCAPE_START.x, ESCAPE_START.y)
	runner.reset_at(Vector3(start.x, 0.1, start.y), 0.0)
	runner.rotation.y = PI
	runner.controller = null
	# Cuota cumplida de antemano por el camino normal: dos blancos derribados por este Runner.
	for prey: Runner in spawn_targets([ESCAPE_START + Vector2(-6, 0), ESCAPE_START + Vector2(6, 0)]):
		var hit := DamageInfo.new()
		hit.type = Enums.DamageType.BARRIER
		hit.source = runner
		hit.weapon_id = &"barrier"
		prey.health.apply(hit)
	EventBus.purge_started.connect(_start_escape, CONNECT_ONE_SHOT)


## Ronda 1 en juego: el piloto entra en la sala 1, derriba dos blancos con el láser para
## cumplir la cuota y vuelve al portal, que solo entonces le deja pasar.
func start_quota_preview() -> void:
	start_round(1)
	clock.tick(Balance.get_f("round.intro_s") + Balance.get_f("round.countdown_s") + 0.001)
	_prey = spawn_targets(QUOTA_TARGETS)
	_gate = 1
	_reset_runner()
	_route_name = "cuota"
	_route = [greybox.corridor_point(1, 2, 24), greybox.corridor_point(1, -2, 84),
			greybox.room_point(-14, 5), greybox.room_point(HUNT_POINT.x, HUNT_POINT.y)]
	_hunt_at = _route.size() - 1
	for point: Vector2 in [Vector2(-12, 5), Vector2(-2, 2)]:
		_route.append(greybox.room_point(point.x, point.y))
	_route.append(greybox.corridor_point(1, 0, 36))
	_route.append(Vector2(0, -20))
	_route.append(Vector2(0, -2))
	_waypoint = 0
	_time = 0.0
	route_events = {}
	route_finished = false
	runner.controller = null


## Blancos de práctica: Runners quietos que participan en la ronda (sus bajas cuentan).
func spawn_targets(points: Array) -> Array[Runner]:
	var spawned: Array[Runner] = []
	for point: Vector2 in points:
		var target: Runner = RUNNER_SCENE.instantiate()
		target.name = "Target%d" % spawned.size()
		add_child(target)
		target.controller = null
		target.get_node("RunnerCamera").set_physics_process(false)
		var world: Vector2 = greybox.room_point(point.x, point.y)
		target.reset_at(Vector3(world.x, 0.1, world.y), PI / 2.0)
		progress.register(target)
		spawned.append(target)
	return spawned


func _start_escape() -> void:
	_gate = 1
	_route_name = "huida"
	_route = []
	for point: Vector2 in ESCAPE_ROUTE:
		_route.append(greybox.room_point(point.x, point.y))
	_route.append(greybox.corridor_point(1, 0, 36))
	_route.append(Vector2(0, -20))
	_route.append(Vector2(0, -2))
	_waypoint = 0
	_time = 0.0
	route_events = {}
	route_finished = false


## Rutas "a" y "b" recorren la sala 1; "2", "3" y "4" las salas homónimas.
func start_route(key: String) -> void:
	_gate = key.to_int() if key.is_valid_int() else 1
	_reset_runner()
	_route_name = key
	_route = []
	if greybox.is_large():
		_route.append(greybox.corridor_point(_gate, 2, 24))
		_route.append(greybox.corridor_point(_gate, -2, 84))
		for point: Vector2 in LARGE_ROUTES[key]:
			_route.append(greybox.room_point(point.x, point.y, _gate))
		var axis: Vector3 = greybox.GATES[_gate]
		_route.append(greybox.corridor_point(_gate, 0, 36))
		_route.append(Vector2(axis.x, axis.z) * 20.0)
		# Sin cuota el portal no deja pasar: la exploración termina en la rampa, al pie del portal.
		_route.append(Vector2(axis.x, axis.z) * PORTAL_FOOT_M)
	else:
		for point: Vector2 in ROUTES[key]:
			_route.append(greybox.map_point(point))
	_waypoint = 0
	_time = 0.0
	_wall_hits = 0
	route_events = {}
	route_finished = false
	runner.controller = null


func _process(_delta: float) -> void:
	var area: int = tracker.area_of(runner)
	var text: String = "ÁREA %s" % (str(area) if area >= 0 else "—")
	if clock.state != RoundManager.State.LOADING:
		var phase: String = RoundManager.State.keys()[clock.state]
		var seconds: int = ceili(clock.seconds_left)
		text += "   |   R%d · %s · %02d:%02d" % [clock.round_index, phase, seconds / 60,
				seconds % 60]
		if clock.state == RoundManager.State.PURGE:
			text += "   |   FRENTE A %.0f m DEL HUB" % purge.front_along()
	if clock.state != RoundManager.State.LOADING:
		text += "\nCUOTA %d / %d   |   PUNTAJE %d" % [progress.kills_for(runner), clock.quota,
				score.points_for(runner)]
		text += "   |   PORTAL ABIERTO" if portal.eligible(runner) else ""
	if runner.health.destroyed:
		text += "   |   PURGADO"
	elif _escaped:
		text += "   |   ESCAPÓ POR EL PORTAL"
	status.text = text
	status.modulate = (Color(1, 0.3, 0.3) if clock.state == RoundManager.State.PURGE
			or (clock.state == RoundManager.State.PLAYING
			and clock.seconds_left <= Balance.get_f("round.warning_at_s"))
			else Color(1, 0.85, 0.4))


func _physics_process(delta: float) -> void:
	if overview.current:
		_overview_angle += delta * 0.25
		var focus := Vector3.ZERO if greybox.is_large() else Vector3(0, 0, greybox.room_center_z / 2.0)
		var reach: float = absf(greybox.room_center_z) * (1.6 if greybox.is_large() else 1.05)
		overview.position = focus + Vector3(sin(_overview_angle) * reach, reach * 1.25,
				cos(_overview_angle) * reach)
		overview.look_at(focus)
	if runner.position.y < -8.0:
		_reset_runner()
	if _route.is_empty() or _waypoint >= _route.size():
		return
	_time += delta
	if _hunting:
		_hunt()
	else:
		_drive_toward(_route[_waypoint])
	_track_events()


func _drive_toward(target: Vector2) -> void:
	var here := Vector2(runner.global_position.x, runner.global_position.z)
	if here.distance_to(target) < ARRIVE_M:
		_hunting = _waypoint == _hunt_at
		_waypoint += 1
		if _waypoint >= _route.size():
			runner.input_frame = InputFrame.new()
			_log("fin de ruta")
			route_finished = true
			print("ROUTE %s %s paredes=%d" % [
				_route_name.to_upper(), JSON.stringify(route_events), _wall_hits])
		return
	var forward: Vector3 = -runner.global_basis.z
	var wanted := Vector3(target.x - here.x, 0, target.y - here.y).normalized()
	var flat := Vector3(forward.x, 0, forward.z).normalized()
	var angle: float = atan2(flat.cross(wanted).y, flat.dot(wanted))
	var frame := InputFrame.new()
	frame.steering = clampf(-angle * 2.5, -1.0, 1.0)
	frame.throttle = 1.0 if absf(angle) < 0.6 else 0.4
	# Frenada previa a curvas cerradas, como haría un piloto: mira el ángulo del tramo siguiente.
	var speed: float = Vector2(runner.velocity.x, runner.velocity.z).length()
	var corner: float = _corner_angle()
	if here.distance_to(target) < CORNER_LOOKAHEAD_M and corner > deg_to_rad(50.0):
		frame.throttle = 0.5
		frame.brake = 0.5 if speed > CORNER_SPEED_MPS else 0.0
	if absf(angle) > 1.2:
		frame.brake = 0.6
	runner.input_frame = frame


## Apunta al primer blanco vivo sin avanzar y dispara cuando está dentro del margen de mira.
func _hunt() -> void:
	var alive: Array[Runner] = _prey.filter(func(prey: Runner) -> bool:
		return is_instance_valid(prey) and not prey.health.destroyed)
	if alive.is_empty():
		_hunting = false
		_log("cuota cumplida")
		return
	var offset: Vector3 = alive[0].global_position - runner.global_position
	var forward: Vector3 = -runner.global_basis.z
	var flat := Vector3(forward.x, 0, forward.z).normalized()
	var wanted := Vector3(offset.x, 0, offset.z).normalized()
	var angle: float = atan2(flat.cross(wanted).y, flat.dot(wanted))
	var frame := InputFrame.new()
	frame.steering = clampf(-angle * 2.5, -1.0, 1.0)
	frame.brake = 1.0
	frame.laser = absf(angle) < deg_to_rad(AIM_TOLERANCE_DEG)
	runner.input_frame = frame


func _on_escaped(escapee: Runner, _time_left: float) -> void:
	if escapee == runner:
		_escaped = true
		_log("escapa por el portal")


func _corner_angle() -> float:
	if _waypoint == 0 or _waypoint + 1 >= _route.size():
		return 0.0
	var a: Vector2 = _route[_waypoint] - _route[_waypoint - 1]
	var b: Vector2 = _route[_waypoint + 1] - _route[_waypoint]
	return absf(a.angle_to(b))


func _track_events() -> void:
	var p: Vector3 = runner.global_position
	var along: float = p.dot(greybox.GATES[_gate])
	var room_key: String = "entra sala %d" % _gate
	if along > greybox.corridor_end:
		_log(room_key)
	if greybox.is_large():
		if p.y > greybox.LARGE_LEDGE_HEIGHT - 0.3 and along > greybox.corridor_end:
			_log("sobre pasarela/plataforma")
	else:
		var platform: Rect2 = greybox.map_rect(greybox.PLATFORM)
		if p.y > greybox.PLATFORM_HEIGHT - 0.2 and platform.has_point(Vector2(p.x, p.z)):
			_log("sobre P1")
	if route_events.has(room_key) and Vector2(p.x, p.z).length() < greybox.hub_radius:
		_log("vuelve al hub")
	var radial: float = Vector2(p.x, p.z).length()
	if radial <= PORTAL_FOOT_M + ARRIVE_M + 0.5 and route_events.has(room_key):
		_log("llega al portal")
	if p.y > greybox.PODIUM_HEIGHT - 0.2 and radial < greybox.PODIUM_RADIUS:
		_log("sobre podio")
	if runner.is_on_wall() and not _was_on_wall:
		_wall_hits += 1
		var hit: String = ""
		for index: int in range(runner.get_slide_collision_count()):
			var collision: KinematicCollision3D = runner.get_slide_collision(index)
			if absf(collision.get_normal().y) < 0.7:
				hit = str(collision.get_collider().get_path()).get_slice("Greybox/", 1)
		_log("pared %d (%.1f, %.1f) %s" % [_wall_hits, p.x, p.z, hit])
	_was_on_wall = runner.is_on_wall()


func _log(event: String) -> void:
	if not route_events.has(event):
		route_events[event] = snappedf(_time, 0.01)
		if "--route-log" in OS.get_cmdline_user_args():
			print("EVENT %.2f %s wp=%d %s" % [_time, event, _waypoint, runner.global_position])


func _reset_runner() -> void:
	var spawn: Dictionary = PenalAltiplanoGreybox.spawn_transforms()[2 * (_gate - 1)]
	runner.reset_at(spawn.position + Vector3.UP * 0.1, spawn.yaw)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		start_round(clock.round_index % 3 + 1 if clock.state != RoundManager.State.LOADING else 1)
	elif event.is_action_pressed("reset_runner"):
		_reset_runner()
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
