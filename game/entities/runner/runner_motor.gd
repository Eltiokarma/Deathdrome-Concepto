class_name RunnerMotor
extends Node
## CharacterBody3D conserva la colisión; cuatro sondas suavizan la pose visual.

var jump_cooldown: float = 0.0
var _wall_contact: bool = false


func reset() -> void:
	jump_cooldown = 0.0
	_wall_contact = false


func step(body: Runner, frame: InputFrame, delta: float) -> void:
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	var grounded: bool = body.is_on_floor()
	var control: float = 1.0 if grounded else Balance.get_f("movement.air_control")
	var turn: float = deg_to_rad(body.stats.turn_rate_deg_s) * frame.steering * control
	body.rotate_y(-turn * delta)
	var normal: Vector3 = body.get_floor_normal() if grounded else Vector3.UP
	var forward: Vector3 = (-body.global_basis.z).slide(normal).normalized()
	var right: Vector3 = forward.cross(normal).normalized()
	var speed: float = body.velocity.dot(forward)
	var lateral: float = body.velocity.dot(right)
	var acceleration: float = body.stats.max_speed_mps / body.stats.accel_time_s
	var target: float = frame.throttle * body.stats.max_speed_mps
	var rate: float = acceleration * control
	if frame.brake > 0.0:
		target = 0.0
		rate *= Balance.get_f("movement.brake_mult") * frame.brake
	elif frame.throttle <= 0.0:
		rate *= Balance.get_f("movement.coast_mult")
	speed = move_toward(speed, target, rate * delta)
	lateral *= exp(-body.stats.lateral_grip * Balance.get_f("movement.grip_damping") * control * delta)
	var planar: Vector3 = forward * speed + right * lateral
	body.velocity.x = planar.x
	body.velocity.z = planar.z
	var gravity: float = Balance.get_f("movement.gravity_mps2")
	if grounded:
		body.velocity.y = planar.y
	if grounded and frame.jump and jump_cooldown <= 0.0:
		# Corrección de medio paso para que el integrador discreto llegue al apogeo.
		body.velocity.y = sqrt(2.0 * gravity * Balance.get_f("movement.jump_apex_m"))
		body.velocity.y += gravity * delta * 0.5
		jump_cooldown = Balance.get_f("movement.jump_cooldown_s")
	body.velocity.y -= gravity * delta
	body.move_and_slide()
	var touching_wall: bool = body.is_on_wall()
	if touching_wall and not _wall_contact:
		var retained: float = 1.0 - Balance.get_f("movement.wall_hit_speed_loss")
		body.velocity.x *= retained
		body.velocity.z *= retained
	_wall_contact = touching_wall
	_update_ground_pose(body, delta)


func _update_ground_pose(body: Runner, delta: float) -> void:
	var normal := Vector3.ZERO
	var hits: int = 0
	for ray: RayCast3D in body.get_node("GroundRays").get_children():
		ray.force_raycast_update()
		if ray.is_colliding():
			normal += ray.get_collision_normal()
			hits += 1
	var target := Basis.IDENTITY
	if hits > 0:
		normal = body.global_basis.inverse() * normal.normalized()
		var forward: Vector3 = Vector3.FORWARD.slide(normal).normalized()
		target = Basis(forward.cross(normal), normal, -forward).orthonormalized()
	var weight: float = 1.0 - exp(-Balance.get_f("movement.pose_response") * delta)
	body.model.basis = body.model.basis.slerp(target, weight).orthonormalized()
