class_name LaserWeapon
extends Node3D
## Hitscan a cadencia fija, selección angular y rampa integrada por intervalo de tiro.

var target: Runner
var _ramp_target: WeakRef
var _ramp_time: float = 0.0
var _idle: float = INF
var _charge: float = 0.0
var _beam_life: float = 0.0
var _beam := MeshInstance3D.new()
var _marker := Label3D.new()
@onready var runner: Runner = get_parent() as Runner


func _ready() -> void:
	add_child(_beam)
	add_child(_marker)
	_marker.text = "▼"
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.pixel_size = 0.01
	_marker.hide()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.3, 0.9, 1.0)
	_beam.material_override = material


func reset() -> void:
	target = null
	_ramp_target = null
	_ramp_time = 0.0
	_idle = INF
	_charge = 0.0
	_beam.hide()
	_marker.hide()


func tick(delta: float, firing: bool) -> void:
	_marker.visible = firing and is_instance_valid(target) and not target.health.destroyed
	if _marker.visible:
		_marker.global_position = target.global_position + Vector3.UP * 1.5
		_marker.modulate = runner.stats.color
	_idle += delta
	_beam_life -= delta
	_beam.visible = _beam_life > 0.0
	if _idle >= Balance.get_f("weapons.laser.ramp_reset_s"):
		_ramp_target = null
		_ramp_time = 0.0
	if not firing or runner.health.destroyed or runner.health.in_safe_zone:
		_charge = 0.0
		target = null
		return
	if Balance.get_b("respawn.spawn_shield_breaks_on_fire"):
		runner.health.spawn_shield_s = 0.0
	var period: float = 1.0 / Balance.get_f("weapons.laser.fire_rate_hz")
	_charge += delta
	while _charge + 0.000001 >= period:
		_charge -= period
		_fire(period)


func _fire(period: float) -> void:
	var origin: Vector3 = global_position
	target = acquire_target()
	var endpoint: Vector3 = origin - runner.global_basis.z * Balance.get_f("weapons.laser.range_m")
	if target != null:
		endpoint = target.global_position + Vector3.UP * 0.35
	else:
		var hit: Dictionary = _ray(origin, endpoint)
		if not hit.is_empty():
			endpoint = hit.position
		_show_beam(origin, endpoint)
		return
	var previous: Runner = _ramp_target.get_ref() as Runner if _ramp_target != null else null
	if previous != target:
		_ramp_time = 0.0
	var info := DamageInfo.new()
	info.type = Enums.DamageType.LASER
	info.source = runner
	info.weapon_id = &"laser"
	info.direction = endpoint - origin
	info.position = endpoint
	info.amount = integrated_damage(_ramp_time + period) - integrated_damage(_ramp_time)
	if target.health.apply(info) > 0.0:
		_ramp_target = weakref(target)
		_ramp_time += period
		_idle = 0.0
	else:
		_ramp_target = null
		_ramp_time = 0.0
	_show_beam(origin, endpoint)


func acquire_target() -> Runner:
	var best: Runner
	var best_angle: float = INF
	var best_distance: float = INF
	var origin: Vector3 = global_position
	var limit: float = deg_to_rad(Balance.get_f("weapons.laser.autoaim_half_angle_deg"))
	for candidate: Runner in get_tree().get_nodes_in_group("runners"):
		if candidate == runner or candidate.health.destroyed or candidate.health.in_safe_zone:
			continue
		var point: Vector3 = candidate.global_position + Vector3.UP * 0.35
		var offset: Vector3 = point - origin
		var distance: float = offset.length()
		var angle: float = (-runner.global_basis.z).angle_to(offset)
		if distance > Balance.get_f("weapons.laser.range_m") or angle > limit:
			continue
		var hit: Dictionary = _ray(origin, point)
		if hit.get("collider") != candidate:
			continue
		if angle < best_angle or (is_equal_approx(angle, best_angle) and distance < best_distance):
			best = candidate
			best_angle = angle
			best_distance = distance
	return best


func integrated_damage(seconds: float) -> float:
	var duration: float = Balance.get_f("weapons.laser.ramp_time_s")
	var multiplier: float = Balance.get_f("weapons.laser.ramp_max_mult")
	var dps: float = Balance.get_f("weapons.laser.damage_per_shot") * Balance.get_f(
		"weapons.laser.fire_rate_hz"
	)
	var ramp: float = minf(seconds, duration)
	return dps * (ramp + (multiplier - 1.0) * ramp * ramp / (2.0 * duration)
		+ maxf(0.0, seconds - duration) * multiplier)


func _ray(origin: Vector3, endpoint: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint, 35, [runner.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)


func _show_beam(origin: Vector3, endpoint: Vector3) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(to_local(origin))
	mesh.surface_add_vertex(to_local(endpoint))
	mesh.surface_end()
	_beam.mesh = mesh
	_beam_life = 0.06
	_beam.show()
