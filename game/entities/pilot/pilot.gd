class_name Pilot
extends CharacterBody3D
## PUR-023: piloto eyectado al morir el Runner. Huye en línea recta durante
## `death.pilot_window_s` a `death.pilot_speed_mps`; si nadie lo derriba en ese tiempo, lo
## recogen y desaparece. Derribarlo emite `mercy_kill` (puntos al atacante, sin cuota) y
## retrasa la reaparición de su dueño. Sin armas ni control del jugador por ahora.

var owner_runner: Runner
var integrity: float = 0.0
var remaining: float = 0.0
var destroyed: bool = false
var _direction := Vector3.FORWARD


func _ready() -> void:
	add_to_group("pilots")
	collision_layer = 0
	collision_mask = 1


func setup(owner_value: Runner, origin: Vector3, direction: Vector3) -> void:
	owner_runner = owner_value
	integrity = Balance.get_f("death.pilot_integrity")
	remaining = Balance.get_f("death.pilot_window_s")
	var flat := Vector3(direction.x, 0, direction.z)
	_direction = flat.normalized() if not flat.is_zero_approx() else Vector3.FORWARD
	global_position = origin + Vector3.UP * 0.2
	look_at(global_position + _direction, Vector3.UP)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.25
	capsule.height = 1.0
	var material := StandardMaterial3D.new()
	material.albedo_color = owner_value.stats.color if owner_value.stats else Color.WHITE
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.6
	capsule.material = material
	body.mesh = capsule
	body.position.y = 0.5
	add_child(body)
	var shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.25
	capsule_shape.height = 1.0
	shape.shape = capsule_shape
	shape.position.y = 0.5
	add_child(shape)


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if destroyed or get_tree().paused or not is_finite(delta) or delta <= 0.0:
		return
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var speed: float = Balance.get_f("death.pilot_speed_mps")
	velocity.x = _direction.x * speed
	velocity.z = _direction.z * speed
	velocity.y -= Balance.get_f("movement.gravity_mps2") * delta
	if is_on_floor():
		velocity.y = 0.0
	move_and_slide()


func is_safe() -> bool:
	for zone: SafeZone in get_tree().get_nodes_in_group("safe_zones"):
		if zone.active() and zone.to_local(global_position).length() <= zone.radius:
			return true
	return false


func apply(info: DamageInfo) -> float:
	if destroyed or info == null or not is_finite(info.amount) or info.amount <= 0.0:
		return 0.0
	var source: Runner = info.source if is_instance_valid(info.source) else null
	if source == owner_runner or (info.type != Enums.DamageType.PURGE and (is_safe()
			or (source != null and source.health.in_safe_zone))):
		return 0.0
	var amount: float = info.amount
	if info.type == Enums.DamageType.LASER and source != null:
		amount *= source.stats.laser_mult
	var applied: float = minf(amount, integrity)
	integrity -= applied
	if integrity <= 0.0:
		destroyed = true
		hide()
		if source != null and is_instance_valid(owner_runner):
			EventBus.mercy_kill.emit(source, owner_runner)
		queue_free()
	return applied
