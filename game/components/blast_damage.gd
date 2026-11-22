class_name BlastDamage
extends RefCounted
## Explosion de altura limitada. Evalua el solapamiento vertical del cuerpo y comprueba
## visibilidad hasta su centro: saltar por encima o cubrirse evita el impacto.


static func apply(emitter: Node3D, source: Runner, kind: StringName) -> void:
	if not is_instance_valid(emitter) or not emitter.is_inside_tree():
		return
	if kind not in [&"shockwave", &"tower"] or emitter.get_tree().paused:
		return
	if is_instance_valid(source) and source.health.in_safe_zone:
		return
	if in_safe_zone(emitter, emitter.global_position):
		return
	var prefix: String = "weapons.shockwave" if kind == &"shockwave" else "hazards.fusion_tower"
	var radius: float = Balance.get_f(prefix + ".radius_m")
	var height: float = Balance.get_f(prefix + ".height_m")
	var requires_los: bool = Balance.get_b(prefix + ".requires_los")
	var origin: Vector3 = emitter.global_position
	var center: Vector3 = origin + Vector3.UP * height * 0.5
	var ignored: Array[RID] = []
	if emitter is CollisionObject3D:
		ignored.append((emitter as CollisionObject3D).get_rid())
	# Primero encolar torres: una baja no cambia la identidad de quien inicio la cadena.
	for tower: Node3D in emitter.get_tree().get_nodes_in_group("fusion_towers"):
		if tower == emitter or not _overlaps(origin, tower, radius, height):
			continue
		var exclude: Array[RID] = ignored.duplicate()
		if tower is CollisionObject3D:
			exclude.append((tower as CollisionObject3D).get_rid())
		var point: Vector3 = tower.get_node("CollisionShape3D").global_position
		if not requires_los or _visible(emitter, center, point, exclude):
			if kind == &"tower":
				tower.queue_chain(source)
			else:
				tower.trigger(source)
	for victim: Runner in emitter.get_tree().get_nodes_in_group("runners"):
		if victim.health.destroyed or (victim == source and kind == &"shockwave"):
			continue
		if not _overlaps(origin, victim, radius, height):
			continue
		var point: Vector3 = victim.get_node("CollisionShape3D").global_position
		if requires_los and not _visible(emitter, center, point, ignored):
			continue
		var offset: Vector3 = victim.global_position - origin
		var distance: float = Vector2(offset.x, offset.z).length()
		var info := DamageInfo.new()
		info.amount = lerpf(Balance.get_f(prefix + ".damage_center"),
				Balance.get_f(prefix + ".damage_edge"), clampf(distance / radius, 0.0, 1.0))
		info.type = Enums.DamageType.SHOCKWAVE if kind == &"shockwave" else Enums.DamageType.TOWER
		info.weapon_id = kind
		info.source = source if is_instance_valid(source) else null
		info.direction = offset
		info.position = point
		victim.health.apply(info)
	var pulse := BlastPulse.new()
	emitter.get_parent().add_child(pulse)
	pulse.global_position = origin
	pulse.setup(radius, height, Color(0.3, 0.8, 1.0) if kind == &"shockwave"
			else Color(1.0, 0.55, 0.1))


static func in_safe_zone(context: Node, point: Vector3) -> bool:
	for zone: SafeZone in context.get_tree().get_nodes_in_group("safe_zones"):
		if not zone.active():
			continue
		var local: Vector3 = zone.to_local(point)
		if Vector2(local.x, local.z).length() <= zone.radius and absf(local.y) <= zone.height * 0.5:
			return true
	return false


static func _overlaps(origin: Vector3, body: Node3D, radius: float, height: float) -> bool:
	var offset: Vector3 = body.global_position - origin
	if Vector2(offset.x, offset.z).length_squared() > radius * radius:
		return false
	var collider: CollisionShape3D = body.get_node("CollisionShape3D")
	var basis: Basis = collider.global_basis
	var extent: float = 0.0
	if collider.shape is BoxShape3D:
		var half: Vector3 = (collider.shape as BoxShape3D).size * 0.5
		extent = (absf(basis.x.y) * half.x + absf(basis.y.y) * half.y
				+ absf(basis.z.y) * half.z)
	elif collider.shape is CylinderShape3D:
		var cylinder: CylinderShape3D = collider.shape as CylinderShape3D
		extent = absf(basis.y.y) * cylinder.height * 0.5 + cylinder.radius * (
				sqrt(basis.x.y * basis.x.y + basis.z.y * basis.z.y))
	var center_y: float = collider.global_position.y
	return center_y + extent >= origin.y and center_y - extent <= origin.y + height


static func _visible(context: Node3D, origin: Vector3, point: Vector3,
		ignored: Array[RID]) -> bool:
	if origin.is_equal_approx(point):
		return true
	var query := PhysicsRayQueryParameters3D.create(origin, point, 33, ignored)
	return context.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
