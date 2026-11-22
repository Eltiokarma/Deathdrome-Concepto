class_name MissileProjectile
extends Node3D
## PUR-042: proyectil barrido, sin autodaño ni explosion radial.
## Velocidad respecto al mundo; no hereda la velocidad del Runner.

const BODY_LENGTH_M := 0.9
const BODY_RADIUS_M := 0.13

var direction: Vector3 = Vector3.FORWARD
var remaining: float = 0.0
var _shooter: WeakRef
var _shooter_life: int = -1
var _target: WeakRef
var _target_life: int = -1
var _spent: bool = false


func _ready() -> void:
	add_to_group("weapon_projectiles")
	var mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = BODY_RADIUS_M
	body.height = BODY_LENGTH_M
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.65, 0.15)
	body.material = material
	mesh.mesh = body
	mesh.rotation.x = PI / 2.0
	add_child(mesh)


## Agregar al arbol y colocar en el muzzle antes de llamar setup.
func setup(shooter: Runner, heading: Vector3, locked: Runner = null) -> void:
	if not is_instance_valid(shooter) or not heading.is_finite() or heading.is_zero_approx():
		_finish()
		return
	_shooter = weakref(shooter)
	_shooter_life = shooter.health.life_id
	direction = heading.normalized()
	remaining = Balance.get_f("weapons.missile.lifetime_s")
	if is_instance_valid(locked) and locked != shooter:
		_target = weakref(locked)
		_target_life = locked.health.life_id
	_orient()


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if _spent or get_tree().paused or not is_finite(delta) or delta <= 0.0:
		return
	var shooter: Runner = _shooter.get_ref() as Runner if _shooter != null else null
	# La muerte no borra un misil en vuelo, pero reaparecer comienza otra vida.
	if not is_instance_valid(shooter) or shooter.is_queued_for_deletion() or (
			shooter.health.life_id != _shooter_life):
		_finish()
		return
	var step: float = minf(delta, remaining)
	if step <= 0.0:
		_finish()
		return
	_steer(step)
	var endpoint: Vector3 = global_position + (
			direction * Balance.get_f("weapons.missile.speed_mps") * step)
	var query := PhysicsRayQueryParameters3D.create(
			global_position, endpoint, 35, [shooter.get_rid()])
	query.hit_from_inside = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	remaining = maxf(0.0, remaining - step)
	if not hit.is_empty():
		global_position = hit.position
		_finish()
		_impact(hit.collider, shooter)
		return
	global_position = endpoint
	_orient()
	if remaining <= 0.0:
		_finish()


func _steer(delta: float) -> void:
	var target: Runner = _target.get_ref() as Runner if _target != null else null
	if not _valid_target(target):
		_target = null
		return
	var aim: Vector3 = (target.get_node("CollisionShape3D") as CollisionShape3D).global_position
	var wanted: Vector3 = (aim - global_position).normalized()
	if wanted.is_zero_approx():
		return
	var angle: float = direction.angle_to(wanted)
	if is_zero_approx(angle):
		return
	var axis: Vector3 = direction.cross(wanted)
	if axis.is_zero_approx():
		axis = direction.cross(Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)
	var maximum: float = deg_to_rad(Balance.get_f("weapons.missile.turn_rate_deg_s")) * delta
	direction = direction.rotated(axis.normalized(), minf(angle, maximum)).normalized()


func _valid_target(target: Runner) -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion() and (
			target.is_in_group("runners") and not target.health.destroyed
			and not target.health.in_safe_zone and not target.health.cloaked
			and target.health.life_id == _target_life)


func _impact(body: Object, shooter: Runner) -> void:
	var victim: Runner = body as Runner
	if victim != null and victim != shooter and victim.is_in_group("runners"):
		var damage := DamageInfo.new()
		damage.type = Enums.DamageType.MISSILE
		damage.amount = Balance.get_f("weapons.missile.damage")
		damage.source = shooter
		damage.weapon_id = &"missile"
		damage.direction = direction
		damage.position = global_position
		victim.health.apply(damage)
	elif is_instance_valid(body) and body.has_method("trigger"):
		body.call("trigger", shooter)


func _orient() -> void:
	look_at(global_position + direction,
			Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)


func _finish() -> void:
	if _spent:
		return
	_spent = true
	set_physics_process(false)
	remove_from_group("weapon_projectiles")
	hide()
	queue_free()
