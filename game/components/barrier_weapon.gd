class_name BarrierWeapon
extends Node
## Energía y emisión por InputFrame; los segmentos persisten al morir el dueño.

var energy: float = 0.0
var segments: Array[BarrierSegment] = []
var _idle: float = 0.0
var _sample: float = 0.0
var _drawing: bool = false
var _anchor := Vector3.ZERO
var _material := StandardMaterial3D.new()
@onready var runner: Runner = get_parent() as Runner


func _ready() -> void:
	process_physics_priority = -20
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index: int in range(Balance.get_i("weapons.barrier.pool_size")):
		var segment := BarrierSegment.new()
		add_child(segment)
		segments.append(segment)


func reset() -> void:
	energy = runner.stats.barrier_energy
	_idle = 0.0
	_sample = 0.0
	_drawing = false
	_material.albedo_color = runner.stats.color
	for segment: BarrierSegment in segments:
		segment.deactivate()


func _physics_process(delta: float) -> void:
	advance_segments(delta)


func advance_segments(delta: float) -> void:
	if get_tree().paused or not is_finite(delta) or delta < 0.0:
		return
	for segment: BarrierSegment in segments:
		segment.tick(delta)


func tick(delta: float, held: bool) -> void:
	if get_tree().paused or not is_finite(delta) or delta <= 0.0:
		return
	var permitted: bool = held and not runner.health.destroyed and not runner.health.in_safe_zone
	if not permitted:
		_drawing = false
		_sample = 0.0
		var delay: float = Balance.get_f("weapons.barrier.regen_delay_s")
		var recharge: float = maxf(0.0, _idle + delta - delay) - maxf(0.0, _idle - delay)
		_idle += delta
		energy = minf(runner.stats.barrier_energy,
			energy + recharge * Balance.get_f("weapons.barrier.regen_per_s"))
		return
	_idle = 0.0
	if energy <= 0.0:
		_drawing = false
		return
	if Balance.get_b("respawn.spawn_shield_breaks_on_fire"):
		runner.health.spawn_shield_s = 0.0
	var point: Vector3 = runner.global_position + runner.global_basis.z * Balance.get_f(
		"weapons.barrier.rear_offset_m")
	if not _drawing:
		_anchor = point
		_sample = 0.0
		_drawing = true
	var available: float = minf(delta, energy / Balance.get_f("weapons.barrier.drain_per_s"))
	energy = maxf(0.0, energy - available * Balance.get_f("weapons.barrier.drain_per_s"))
	_sample += available
	if _sample >= Balance.get_f("weapons.barrier.sample_interval_s"):
		_sample = fmod(_sample, Balance.get_f("weapons.barrier.sample_interval_s"))
		if _anchor.distance_to(point) <= Balance.get_f("weapons.barrier.max_gap_m"):
			emit_segment(_anchor, point)
		_anchor = point


func emit_segment(start: Vector3, end: Vector3) -> BarrierSegment:
	for segment: BarrierSegment in segments:
		if segment.remaining <= 0.0:
			return segment if segment.activate(start, end, runner, _material) else null
	return null
