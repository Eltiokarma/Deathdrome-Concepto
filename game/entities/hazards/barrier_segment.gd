class_name BarrierSegment
extends StaticBody3D
## Segmento reutilizable; colisión sólida para rivales y excepción para su dueño.

var remaining: float = 0.0
var source: WeakRef
var shape := BoxShape3D.new()
var mesh := BoxMesh.new()
var visual := MeshInstance3D.new()
var _query := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	top_level = true
	collision_layer = 0
	collision_mask = 0
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	visual.mesh = mesh
	add_child(visual)
	_query.shape = shape
	_query.collision_mask = 2
	hide()


func activate(start: Vector3, end: Vector3, runner: Runner, material: Material) -> bool:
	var offset: Vector3 = (end - start).slide(Vector3.UP)
	if offset.length() < 0.01:
		return false
	global_transform = Transform3D(Basis.looking_at(offset.normalized()), (start + end) * 0.5)
	global_position.y += Balance.get_f("weapons.barrier.segment_height_m") * 0.5
	shape.size = Vector3(Balance.get_f("weapons.barrier.segment_width_m"),
		Balance.get_f("weapons.barrier.segment_height_m") + absf(end.y - start.y), offset.length())
	mesh.size = shape.size
	if touches_safe_zone():
		return false
	source = weakref(runner)
	_query.exclude = [runner.get_rid()]
	add_collision_exception_with(runner)
	visual.material_override = material
	remaining = Balance.get_f("weapons.barrier.segment_lifetime_s")
	collision_layer = 32
	show()
	return true


func deactivate() -> void:
	var runner: Runner = source.get_ref() as Runner if source != null else null
	if runner != null:
		remove_collision_exception_with(runner)
	source = null
	remaining = 0.0
	collision_layer = 0
	hide()


func tick(delta: float) -> void:
	if remaining <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.0 or touches_safe_zone():
		deactivate()
		return
	_query.transform = global_transform
	for hit_info: Dictionary in get_world_3d().direct_space_state.intersect_shape(_query, 16):
		hit(hit_info.collider as Runner)


func hit(victim: Runner) -> void:
	if remaining <= 0.0 or victim == null or touches_safe_zone():
		return
	var info := DamageInfo.new()
	info.type = Enums.DamageType.BARRIER
	info.source = source.get_ref() as Runner if source != null else null
	info.weapon_id = &"barrier"
	victim.health.apply(info)


func touches_safe_zone() -> bool:
	for zone: SafeZone in get_tree().get_nodes_in_group("safe_zones"):
		if zone.intersects_box(global_transform, shape.size):
			return true
	return false
