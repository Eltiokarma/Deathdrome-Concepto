class_name RoundRespawner
extends Node
## PUR-024: reaparición de los participantes en el Área 0 tras `respawn.delay_s`
## (+`respawn.mercy_kill_extra_s` si su piloto fue rematado), en un punto de aparición libre,
## con escudo de `respawn.spawn_shield_s`, integridad y barrera llenas. Sin reaparición
## durante la Purga (`purge.respawn_allowed`). Al empezar cada ronda, los caídos vuelven.
## Los slots de secundarias se vaciarán aquí cuando exista el inventario (PUR-040).

@export var manager_path: NodePath
@export var progress_path: NodePath
var pending: Dictionary = {}
var _cursor: int = 0
@onready var manager: RoundManager = get_node(manager_path)
@onready var progress: RoundProgress = get_node(progress_path)


func _ready() -> void:
	EventBus.runner_destroyed.connect(_on_destroyed)
	EventBus.mercy_kill.connect(_on_mercy)
	EventBus.round_state_changed.connect(_on_state)


func _physics_process(delta: float) -> void:
	tick(delta)


func time_left(runner: Runner) -> float:
	var entry: Dictionary = pending.get(runner.get_instance_id(), {})
	return entry.get("remaining", INF)


func tick(delta: float) -> void:
	if get_tree().paused or not is_finite(delta) or delta < 0.0:
		return
	if manager.state != RoundManager.State.PLAYING:
		return
	for id: int in pending.keys():
		var entry: Dictionary = pending[id]
		var runner: Runner = entry.runner.get_ref() as Runner
		if runner == null or not runner.health.destroyed or runner.health.life_id != entry.life:
			pending.erase(id)
			continue
		entry.remaining = maxf(0.0, entry.remaining - delta)
		if entry.remaining <= 0.0 and respawn(runner, true):
			pending.erase(id)


## Coloca al Runner en el siguiente punto de aparición libre. Devuelve false si todos están
## ocupados (se reintenta en el siguiente tick).
func respawn(runner: Runner, shield: bool) -> bool:
	var spawns: Array[Node] = get_tree().get_nodes_in_group("spawn_points")
	for attempt: int in range(spawns.size()):
		var marker: Node3D = spawns[(_cursor + attempt) % spawns.size()]
		if _occupied(runner, marker):
			continue
		_cursor = (_cursor + attempt + 1) % spawns.size()
		runner.reset_at(marker.global_position + Vector3.UP * 0.1, marker.global_rotation.y)
		if shield:
			runner.health.spawn_shield_s = Balance.get_f("respawn.spawn_shield_s")
		EventBus.runner_respawned.emit(runner)
		return true
	return false


func _on_destroyed(victim: Runner, _killer: Runner, _weapon: StringName) -> void:
	if not progress.is_participant(victim) or manager.state != RoundManager.State.PLAYING:
		return
	pending[victim.get_instance_id()] = {
		"runner": weakref(victim), "life": victim.health.life_id,
		"remaining": Balance.get_f("respawn.delay_s"), "mercy": false,
	}


func _on_mercy(_killer: Runner, owner_runner: Runner) -> void:
	var entry: Dictionary = pending.get(owner_runner.get_instance_id(), {})
	if entry.is_empty() or entry.mercy:
		return
	entry.mercy = true
	entry.remaining += Balance.get_f("respawn.mercy_kill_extra_s")


func _on_state(state: int) -> void:
	if state == RoundManager.State.PURGE and not Balance.get_b("purge.respawn_allowed"):
		pending.clear()
	elif state == RoundManager.State.INTRO:
		pending.clear()
		for runner: Runner in get_tree().get_nodes_in_group("runners"):
			if runner.health.destroyed and progress.is_participant(runner):
				respawn(runner, false)


func _occupied(runner: Runner, marker: Node3D) -> bool:
	var collider: CollisionShape3D = runner.get_node("CollisionShape3D")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.transform = Transform3D(marker.global_basis, marker.global_position) * collider.transform
	query.collision_mask = 2
	query.exclude = [runner.get_rid()]
	return not runner.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
