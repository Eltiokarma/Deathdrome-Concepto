class_name PracticeRespawner
extends Node
## Solo blanco de ensayo. La política de ronda/Purga pertenece a otro sistema.

@export var target_path: NodePath
@export var spawn_position := Vector3(-17, 0.1, 0)
@export var spawn_yaw: float = PI / 2.0
var enabled: bool = true
var remaining: float = 0.0
var pending: bool = false
var blocked: bool = false
var target: Runner


func _ready() -> void:
	target = get_node(target_path) as Runner
	EventBus.runner_destroyed.connect(_on_destroyed)


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not enabled or get_tree().paused or not pending or not is_finite(delta) or delta < 0.0:
		return
	# Un reset manual cancela la reaparición pendiente.
	if not is_instance_valid(target) or not target.health.destroyed:
		cancel()
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining > 0.0:
		return
	blocked = _spawn_occupied()
	if blocked:
		return
	target.reset_at(spawn_position, spawn_yaw)
	target.health.spawn_shield_s = Balance.get_f("respawn.spawn_shield_s")
	cancel()
	EventBus.runner_respawned.emit(target)


func cancel() -> void:
	pending = false
	blocked = false
	remaining = 0.0


func _on_destroyed(victim: Runner, _killer: Runner, _weapon: StringName) -> void:
	if not enabled or victim != target or pending:
		return
	pending = true
	blocked = false
	remaining = Balance.get_f("respawn.delay_s")


func _spawn_occupied() -> bool:
	var collider: CollisionShape3D = target.get_node("CollisionShape3D")
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.transform = Transform3D(Basis(Vector3.UP, spawn_yaw), spawn_position) * collider.transform
	query.collision_mask = 2
	query.exclude = [target.get_rid()]
	return not target.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
