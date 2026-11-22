class_name MissileLock
extends Node
## PUR-041: adquisicion continua por cono, distancia y linea de vision.
## El aviso nace al adquirir el blanco; cambiar de vida o de blanco reinicia el tiempo.

var target: Runner
var progress: float = 0.0
var _elapsed: float = 0.0
var _target_life: int = -1
var _owner_life: int = -1
@onready var runner: Runner = get_parent() as Runner


func tick(delta: float, enabled: bool) -> void:
	if get_tree().paused or not is_finite(delta) or delta < 0.0:
		return
	if not enabled or runner.health.destroyed or runner.health.in_safe_zone or (
			not runner.is_in_group("runners")):
		reset()
		return
	if _owner_life != runner.health.life_id:
		reset()
		_owner_life = runner.health.life_id
	var candidate: Runner = _acquire()
	if candidate != target or (candidate != null and candidate.health.life_id != _target_life):
		reset()
		target = candidate
		if target != null:
			_target_life = target.health.life_id
			EventBus.lock_started.emit(runner, target, &"missile")
	if target == null:
		return
	var duration: float = runner.stats.missile_lock_time_s
	_elapsed = minf(duration, _elapsed + delta)
	progress = clampf(_elapsed / maxf(duration, 0.000001), 0.0, 1.0)


func reset() -> void:
	var previous: Runner = target if is_instance_valid(target) else null
	target = null
	progress = 0.0
	_elapsed = 0.0
	_target_life = -1
	if previous != null:
		EventBus.lock_lost.emit(runner, previous)


func locked_target() -> Runner:
	if progress < 1.0 or not is_instance_valid(target):
		return null
	if runner.health.life_id != _owner_life or runner.health.destroyed or (
			runner.health.in_safe_zone or not runner.is_in_group("runners")):
		return null
	if not _can_target(target):
		return null
	return target if target.health.life_id == _target_life else null


func _acquire() -> Runner:
	var best: Runner
	var best_angle: float = INF
	var best_distance: float = INF
	var origin: Vector3 = _origin()
	for candidate: Runner in get_tree().get_nodes_in_group("runners"):
		if not _can_target(candidate):
			continue
		var offset: Vector3 = _aim_point(candidate) - origin
		var angle: float = (-runner.global_basis.z).angle_to(offset)
		var distance: float = offset.length_squared()
		if angle < best_angle or (is_equal_approx(angle, best_angle) and distance < best_distance):
			best = candidate
			best_angle = angle
			best_distance = distance
	return best


func _can_target(candidate: Runner) -> bool:
	if not is_instance_valid(candidate) or candidate == runner or (
			candidate.is_queued_for_deletion() or not candidate.is_in_group("runners")):
		return false
	if candidate.health.destroyed or candidate.health.in_safe_zone or candidate.health.cloaked:
		return false
	var origin: Vector3 = _origin()
	var endpoint: Vector3 = _aim_point(candidate)
	var offset: Vector3 = endpoint - origin
	if offset.length() > Balance.get_f("weapons.missile.lock_range_m"):
		return false
	var limit: float = deg_to_rad(Balance.get_f("weapons.missile.lock_half_angle_deg"))
	if (-runner.global_basis.z).angle_to(offset) > limit:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint, 35, [runner.get_rid()])
	var hit: Dictionary = runner.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") == candidate


func _origin() -> Vector3:
	return (runner.get_node("LaserWeapon") as Node3D).global_position


func _aim_point(candidate: Runner) -> Vector3:
	return (candidate.get_node("CollisionShape3D") as CollisionShape3D).global_position
