class_name PurgeField
extends Node3D
## Ensayo radial; el dominio final debe definir los frentes de sus cuatro salas.

@export var manager_path: NodePath
@export var start_radius: float = 56.0
@export var hub_radius: float = 7.0
@export var visual_height: float = 12.0
var radius: float = 56.0
var closed: bool = false
var _warned: bool = false
@onready var manager: RoundManager = get_node(manager_path)


func _ready() -> void:
	EventBus.round_state_changed.connect(_on_state)
	EventBus.round_clock_tick.connect(_on_clock)
	_make_warning()
	reset()


func reset() -> void:
	radius = start_radius
	closed = false
	_warned = false
	$Warning.stop()
	$Wall.hide()


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if get_tree().paused or manager.state != RoundManager.State.PURGE:
		return
	if not is_finite(delta) or delta < 0.0:
		return
	_advance(delta, _speed())
	$Wall.visible = radius > 0.0
	$Wall.scale = Vector3(maxf(radius, 0.001), visual_height, maxf(radius, 0.001))
	$Wall.position.y = visual_height * 0.5
	for runner: Runner in get_tree().get_nodes_in_group("runners"):
		if manager.state != RoundManager.State.PURGE:
			break
		if runner.health.destroyed or not contains(runner.global_position):
			continue
		var damage := DamageInfo.new()
		damage.type = Enums.DamageType.PURGE
		damage.weapon_id = &"purge"
		runner.health.apply(damage)
	if radius <= 0.0 and not closed:
		closed = true
		EventBus.purge_closed.emit()


func contains(point: Vector3) -> bool:
	# Columna letal sin límite vertical: saltar/esconderse bajo la arena no evita el cierre.
	var local: Vector3 = to_local(point)
	return radius <= 0.0 or Vector2(local.x, local.z).length() >= radius


## Velocidad de los frentes según Balance (×1.5 en el Dominio 8).
func _speed() -> float:
	var speed: float = Balance.get_f("purge.speed_mps")
	if manager.domain_id == 8:
		speed *= Balance.get_f("purge.domain_8_speed_mult")
	return speed


## Avanza los frentes `delta` segundos. Las subclases (frentes por sala) lo sustituyen.
func _advance(delta: float, speed: float) -> void:
	var remaining: float = delta
	if radius > hub_radius:
		var travel: float = minf(remaining, (radius - hub_radius) / speed)
		radius = maxf(hub_radius, radius - speed * travel)
		remaining -= travel
	radius = maxf(0.0, radius - remaining * hub_radius / Balance.get_f("purge.hub_close_s"))


func _on_state(state: int) -> void:
	if manager.state != state:
		return
	if state == RoundManager.State.INTRO:
		reset()
	elif state == RoundManager.State.PURGE:
		$Wall.show()
	elif state == RoundManager.State.RESULTS:
		$Wall.hide()
		$Warning.stop()


func _on_clock(seconds_left: float) -> void:
	if manager.state != RoundManager.State.PLAYING or _warned:
		return
	if not is_equal_approx(seconds_left, manager.seconds_left):
		return
	if seconds_left <= Balance.get_f("round.warning_at_s"):
		_warned = true
		$Warning.play()


func _make_warning() -> void:
	# Sirena original breve; PCM mono 16 bits generado una vez, sin assets externos.
	var samples := PackedByteArray()
	samples.resize(44100)
	var phase: float = 0.0
	for index: int in range(22050):
		var frequency: float = 660.0 if (index / 5512) % 2 == 0 else 880.0
		phase += TAU * frequency / 22050.0
		samples.encode_s16(index * 2, int(sin(phase) * 6000.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	sound.data = samples
	$Warning.stream = sound
