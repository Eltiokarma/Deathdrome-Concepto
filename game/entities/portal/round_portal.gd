class_name RoundPortal
extends Node3D
## Portal selectivo: colisión por Runner, ascenso y tiempo de entrada inmutable.

@export var manager_path: NodePath
@export var progress_path: NodePath
@export var viewer_path: NodePath
var _admitted: Array[Runner] = []
var _journeys: Dictionary = {}
var _material := StandardMaterial3D.new()
@onready var manager: RoundManager = get_node(manager_path)
@onready var progress: RoundProgress = get_node(progress_path)
@onready var viewer: Runner = get_node(viewer_path)
@onready var gate: StaticBody3D = $Gate


func _ready() -> void:
	$Ring.material_override = _material
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	$Entry.body_entered.connect(_on_entered)
	EventBus.round_state_changed.connect(_on_state)


func _physics_process(delta: float) -> void:
	tick(delta)


func eligible(runner: Runner) -> bool:
	return is_instance_valid(runner) and not runner.health.destroyed and (
		manager.state in [RoundManager.State.PLAYING, RoundManager.State.PURGE]
		and progress.has_quota(runner) and not _journeys.has(runner.get_instance_id())
	)


func is_ascending(runner: Runner) -> bool:
	return is_instance_valid(runner) and _journeys.has(runner.get_instance_id()) and (
		not _journeys[runner.get_instance_id()].done
	)


func tick(delta: float) -> void:
	if get_tree().paused or not is_finite(delta) or delta < 0.0:
		return
	_sync_gate()
	var duration: float = Balance.get_f("portal.ascent_s")
	for id: int in _journeys.keys():
		var journey: Dictionary = _journeys[id]
		var runner: Runner = journey.runner.get_ref() as Runner
		if runner == null or journey.done:
			continue
		journey.elapsed = minf(duration, journey.elapsed + delta)
		var weight: float = journey.elapsed / duration
		var center := Vector3(global_position.x, journey.start.y, global_position.z)
		runner.global_position = journey.start.lerp(center, minf(weight * 3.0, 1.0))
		runner.global_position += Vector3.UP * (
			Balance.get_f("portal.ascent_height_m") * weight * weight)
		if runner == viewer:
			$AscentCamera.global_position = Vector3(global_position.x,
				maxf(global_position.y + 0.6, runner.global_position.y - 2.0),
				global_position.z + 3.0)
			$AscentCamera.look_at(runner.global_position + Vector3.UP)
			$Overlay/Fade.color.a = clampf((weight - 0.75) * 4.0, 0.0, 1.0)
		if journey.elapsed >= duration:
			journey.done = true
			EventBus.runner_escaped.emit(runner, journey.time_left)


func _sync_gate() -> void:
	for runner: Runner in _admitted.duplicate():
		if not is_instance_valid(runner):
			_admitted.erase(runner)
		elif not eligible(runner):
			runner.remove_collision_exception_with(gate)
			_admitted.erase(runner)
	for runner: Runner in get_tree().get_nodes_in_group("runners"):
		if eligible(runner) and runner not in _admitted:
			runner.add_collision_exception_with(gate)
			_admitted.append(runner)
	$Gate/Model.visible = not eligible(viewer) and not _journeys.has(viewer.get_instance_id())
	_material.albedo_color = viewer.stats.color if eligible(viewer) else Color(0.2, 0.2, 0.2)


func _on_entered(body: Node3D) -> void:
	var runner: Runner = body as Runner
	if not eligible(runner):
		return
	_journeys[runner.get_instance_id()] = {
		"runner": weakref(runner), "start": runner.global_position,
		"time_left": manager.seconds_left, "elapsed": 0.0, "done": false,
		"layer": runner.collision_layer, "processing": runner.is_physics_processing(),
	}
	runner.set_physics_process(false)
	runner.velocity = Vector3.ZERO
	runner.laser.reset()
	runner.set_deferred("collision_layer", 0)
	runner.remove_from_group("runners")
	runner.model.show()
	if runner == viewer:
		$Tunnel.show()
		$AscentCamera.make_current()


func _on_state(state: int) -> void:
	if state == RoundManager.State.INTRO:
		reset()
	elif state == RoundManager.State.RESULTS:
		for journey: Dictionary in _journeys.values():
			journey.done = true
		$Overlay/Fade.color.a = 0.0
		$Tunnel.hide()
		viewer.get_node("RunnerCamera/SpringArm3D/Camera3D").make_current()


func reset() -> void:
	for journey: Dictionary in _journeys.values():
		var runner: Runner = journey.runner.get_ref() as Runner
		if runner == null:
			continue
		runner.collision_layer = journey.layer
		runner.set_physics_process(journey.processing)
		runner.add_to_group("runners")
	_journeys.clear()
	for runner: Runner in _admitted:
		if is_instance_valid(runner):
			runner.remove_collision_exception_with(gate)
	_admitted.clear()
	$Tunnel.hide()
	$Overlay/Fade.color.a = 0.0
	viewer.get_node("RunnerCamera/SpringArm3D/Camera3D").make_current()
