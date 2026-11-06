class_name Pickup
extends Area3D
## PUR-040: pickup flotante y giratorio. `kind` = "weapon" (ocupa un slot, reaparece a
## `inventory.weapon_pickup_respawn_s`) o un ítem de `items.*` de uso inmediato (hoy:
## `health_orb`, que solo se recoge si el Runner está dañado).

const BOB_HEIGHT_M := 0.25
const BOB_HZ := 0.6
const SPIN_DEG_S := 90.0
const FLOAT_Y_M := 1.0
const RADIUS_M := 2.0

@export var kind: StringName = &"weapon"
@export var weapon_id: StringName = &"missile"
var available: bool = true
var respawn_left: float = 0.0
var _age: float = 0.0
var _visual := Node3D.new()


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS_M
	shape.shape = sphere
	shape.position.y = FLOAT_Y_M
	add_child(shape)
	add_child(_visual)
	var mesh := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	if kind == &"health_orb":
		var orb := SphereMesh.new()
		orb.radius = 0.45
		orb.height = 0.9
		material.albedo_color = Color(0.4, 1.0, 0.45)
		orb.material = material
		mesh.mesh = orb
	else:
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.5, 1.1)
		material.albedo_color = Color(0.35, 0.8, 1.0)
		box.material = material
		mesh.mesh = box
	material.emission = material.albedo_color * 0.7
	_visual.add_child(mesh)
	body_entered.connect(_on_body_entered)


func pickup_id() -> StringName:
	return weapon_id if kind == &"weapon" else kind


func respawn_time() -> float:
	if kind == &"weapon":
		return Balance.get_f("inventory.weapon_pickup_respawn_s")
	return Balance.get_f("items.%s.respawn_s" % kind)


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if get_tree().paused or not is_finite(delta) or delta <= 0.0:
		return
	_age += delta
	_visual.position.y = FLOAT_Y_M + sin(_age * TAU * BOB_HZ) * BOB_HEIGHT_M
	_visual.rotation.y = deg_to_rad(SPIN_DEG_S) * _age
	if available:
		for body: Node3D in get_overlapping_bodies():
			if try_collect(body as Runner):
				break
		return
	respawn_left -= delta
	if respawn_left <= 0.0:
		available = true
		_visual.show()


func try_collect(runner: Runner) -> bool:
	if not available or runner == null or runner.health.destroyed:
		return false
	if kind == &"weapon":
		if not runner.inventory.add(weapon_id):
			return false
	elif kind == &"health_orb":
		if runner.health.current >= runner.health.maximum:
			return false
		runner.health.heal(Balance.get_f("items.health_orb.heal"))
	else:
		return false
	available = false
	respawn_left = respawn_time()
	_visual.hide()
	EventBus.pickup_collected.emit(runner, pickup_id())
	return true


func _on_body_entered(body: Node3D) -> void:
	try_collect(body as Runner)
