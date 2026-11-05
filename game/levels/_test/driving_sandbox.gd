extends Node3D
## Banco de conducción; selección/reset son herramientas de prueba, no campaña.

const RUNNERS: Array[StringName] = [
	&"amaru", &"kuntur", &"lloqlla", &"puma", &"chikchi", &"illapa", &"wikuna", &"supay",
]
const SPAWN := Vector3(-17, 0.1, 15)

var _combat_preview: bool = false
var _kills: int = 0

var _selection: int = 0
var _show_stats: bool = false
var _preview: bool = false
var _preview_tick: int = 0
@onready var respawner: PracticeRespawner = $PracticeRespawner
@onready var target: Runner = $Target
@onready var runner: Runner = $Runner
@onready var status: Label = $UI/Status
@onready var stats_label: Label = $UI/Stats


func _ready() -> void:
	target.controller = null
	target.get_node("RunnerCamera").set_physics_process(false)
	EventBus.runner_destroyed.connect(_on_destroyed)
	_combat_preview = "--combat-preview" in OS.get_cmdline_user_args()
	if _combat_preview:
		runner.controller = null
		runner.input_frame.laser = true
	$Arena/Overlay.hide()
	# Los rótulos grandes de la vista orbital no deben tapar la conducción.
	for marker: Node in $Arena.get_children():
		if marker is Label3D:
			marker.pixel_size *= 0.25
	$Arena/Camera.set_process(false)
	$Arena/Camera.set_process_unhandled_input(false)
	runner.get_node("RunnerCamera/SpringArm3D/Camera3D").make_current()
	_preview = "--driving-preview" in OS.get_cmdline_user_args()
	if _preview:
		runner.controller = null
		runner.input_frame.throttle = 0.55


func _physics_process(_delta: float) -> void:
	if _preview and not get_tree().paused:
		_preview_tick += 1
		runner.input_frame.jump = _preview_tick == 160
		runner.input_frame.steering = 0.7 if _preview_tick > 235 else 0.0
	if runner.position.y < -8.0:
		runner.reset_at(SPAWN)


func _process(_delta: float) -> void:
	status.text = "%s   ·   %.1f m/s   ·   %s" % [
		runner.stats.display_name.to_upper(), Vector2(runner.velocity.x, runner.velocity.z).length(),
		"PAUSA" if get_tree().paused else "BANCO DE PRUEBAS",
	]
	$UI/CombatStatus.text = "INTEGRIDAD %.0f / %.0f   |   BLANCO %.0f / %.0f   |   BAJAS %d" % [
		runner.current_integrity, runner.stats.max_integrity, target.current_integrity,
		target.stats.max_integrity, _kills]
	var respawn_text: String = ""
	if respawner.pending:
		respawn_text = "PUNTO DE REAPARICIÓN OCUPADO" if respawner.blocked else (
			"BLANCO REAPARECE EN %.1f s" % respawner.remaining
		)
	elif target.health.spawn_shield_s > 0.0:
		respawn_text = "ESCUDO DEL BLANCO: %.1f s" % target.health.spawn_shield_s
	$UI/RespawnStatus.text = respawn_text
	stats_label.visible = _show_stats
	stats_label.text = (
		"Vel. máx.: %.1f m/s  |  Aceleración: %.1f s\n"
		+ "Integridad: %.0f PI  |  Giro: %.0f°/s\n"
		+ "Agarre: %.2f  |  Láser: ×%.2f  |  Barrera: %.0f\n"
		+ "Suelo: %s  |  Recarga de salto: %.2f s"
	) % [runner.stats.max_speed_mps, runner.stats.accel_time_s, runner.stats.max_integrity,
		runner.stats.turn_rate_deg_s, runner.stats.lateral_grip, runner.stats.laser_mult,
		runner.stats.barrier_energy, runner.is_on_floor(), runner.motor.jump_cooldown]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://levels/_test/round_sandbox.tscn")
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
	elif event.is_action_pressed("debug_stats"):
		_show_stats = not _show_stats
	elif event.is_action_pressed("reset_runner"):
		respawner.cancel()
		runner.reset_at(SPAWN)
		target.reset_at(Vector3(-17, 0.1, 0), PI / 2.0)
	elif event.is_action_pressed("select_runner"):
		_selection = (_selection + 1) % RUNNERS.size()
		runner.setup(RUNNERS[_selection])
		runner.reset_at(SPAWN)


func _on_destroyed(victim: Runner, killer: Runner, _weapon: StringName) -> void:
	if victim == target and killer == runner:
		_kills += 1
