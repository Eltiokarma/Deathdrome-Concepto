class_name PenalAltiplanoGreybox
extends Node3D
## Greybox del hub + sala 1 del Dominio 1 (PUR-070 rev. 2).
## Las cotas copian docs/dominios/01_penal_altiplano.md; si cambian, actualizar ficha y pruebas.
## Torres y pickups son solo marcadores de reserva: no tienen comportamiento.

const HUB_RADIUS := 20.0
const HUB_WALL := 1.0
const HUB_CEILING := 6.0
const OCULUS_RADIUS := 6.0
const PODIUM_RADIUS := 5.0
const PODIUM_HEIGHT := 1.5
const PODIUM_RAMP_WIDTH := 4.0
const PODIUM_RAMP_FOOT := 9.5
const PODIUM_RAMP_OVERLAP := 0.4
const SPAWN_RADIUS := 7.0
const SPAWN_OFFSET_DEG := 30.0
const GATE_WIDTH := 8.0
const GATE_HEIGHT := 5.0
const CORRIDOR_END := 34.0
const ROOM_HALF := 18.0
const ROOM_CENTER_Z := -52.0
const ROOM_CEILING := 6.0
const WALL := 1.0
const GROUND_SIZE := Vector2(80, 116)
const GROUND_CENTER_Z := -16.0
const DEFLECTOR := Rect2(-9, -44, 18, 2)
const PLATFORM := Rect2(-18, -70, 8, 16)
const PLATFORM_HEIGHT := 2.0
const RAMP_RA_FOOT_Z := -48.0
const PILLARS := {"C1": Rect2(-2, -59, 2, 2), "C2": Rect2(9, -63, 2, 2)}
const RESERVES := {
	"T1": Vector3(-7, 0, -50), "T2": Vector3(14, 0, -50),
	"M1": Vector3(-14, 2, -64), "M2": Vector3(4, 0, -68), "M3": Vector3(15, 0, -62),
	"H1": Vector3(-1, 0, -66),
}
## Ejes cardinales de las compuertas: 1 norte (abierta), 2 este (abierta, sala sin interior),
## 3 sur y 4 oeste (cerradas en R1).
const GATES := {
	1: Vector3(0, 0, -1), 2: Vector3(1, 0, 0), 3: Vector3(0, 0, 1), 4: Vector3(-1, 0, 0),
}

var _materials: Dictionary = {}


func _ready() -> void:
	_build_materials()
	_build_ground()
	_build_hub()
	_build_podium()
	_build_corridor(1, false)
	_build_corridor(2, true)
	_build_closed_gate(3)
	_build_closed_gate(4)
	_build_room_1()
	_build_spawns()
	_build_reserves()


## Posición y orientación (yaw) de los ocho spawns, mirando hacia afuera.
static func spawn_transforms() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for axis: int in range(4):
		for side: float in [-SPAWN_OFFSET_DEG, SPAWN_OFFSET_DEG]:
			var angle: float = deg_to_rad(axis * 90.0 + side)
			var point := Vector3(sin(angle), 0, -cos(angle)) * SPAWN_RADIUS
			result.append({"position": point, "yaw": -angle})
	return result


func set_ceilings_visible(value: bool) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"greybox_ceiling"):
		if is_ancestor_of(node):
			(node as Node3D).visible = value


func _build_materials() -> void:
	var colors := {
		"floor": Color(0.17, 0.21, 0.25), "hub": Color(0.15, 0.30, 0.27),
		"wall": Color(0.32, 0.39, 0.44), "ceiling": Color(0.24, 0.28, 0.32),
		"ramp": Color(0.85, 0.61, 0.17), "platform": Color(0.29, 0.37, 0.45),
		"block": Color(0.77, 0.35, 0.29), "podium": Color(0.55, 0.80, 0.67),
		"closed": Color(0.75, 0.08, 0.08), "reserve": Color(0.5, 0.8, 1.0, 0.45),
		"tower": Color(1.0, 0.54, 0.4, 0.45), "health": Color(0.6, 0.9, 0.48, 0.45),
	}
	for key: String in colors:
		var material := StandardMaterial3D.new()
		material.albedo_color = colors[key]
		material.roughness = 1.0
		if colors[key].a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materials[key] = material


## Un único suelo de colisión: las juntas entre losas solapadas enganchaban el morro del Runner.
## Los suelos de cada zona son solo visuales.
func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = 1
	ground.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GROUND_SIZE.x, 1.0, GROUND_SIZE.y)
	shape.shape = box
	shape.position = Vector3(0, -0.5, GROUND_CENTER_Z)
	ground.add_child(shape)
	add_child(ground)


func _build_hub() -> void:
	var hub := Node3D.new()
	hub.name = "Hub"
	add_child(hub)
	var floor_disc := _cylinder(hub, "Floor", HUB_RADIUS + HUB_WALL, 0.1, "hub", false)
	floor_disc.position.y = 0.0
	var wall := CSGCombiner3D.new()
	wall.name = "Wall"
	wall.use_collision = true
	hub.add_child(wall)
	var outer := _cylinder(wall, "Outer", HUB_RADIUS + HUB_WALL, HUB_CEILING, "wall", false)
	outer.position.y = HUB_CEILING / 2.0
	var inner := _cylinder(wall, "Inner", HUB_RADIUS, HUB_CEILING + 0.2, "wall", false)
	inner.position.y = HUB_CEILING / 2.0
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	for gate: int in GATES:
		var axis: Vector3 = GATES[gate]
		var cut := CSGBox3D.new()
		cut.name = "Gate%d" % gate
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut.size = _oriented(axis, Vector3(GATE_WIDTH, GATE_HEIGHT, 4.0))
		cut.position = axis * (HUB_RADIUS + 0.5) + Vector3.UP * GATE_HEIGHT / 2.0
		wall.add_child(cut)
	var ceiling := CSGCombiner3D.new()
	ceiling.name = "Ceiling"
	ceiling.use_collision = true
	ceiling.add_to_group(&"greybox_ceiling")
	hub.add_child(ceiling)
	var slab := _cylinder(ceiling, "Slab", HUB_RADIUS + HUB_WALL, 0.5, "ceiling", false)
	slab.position.y = HUB_CEILING + 0.25
	var oculus := _cylinder(ceiling, "Oculus", OCULUS_RADIUS, 0.7, "ceiling", false)
	oculus.position.y = HUB_CEILING + 0.25
	oculus.operation = CSGShape3D.OPERATION_SUBTRACTION
	_label(hub, "ÁREA 0", Vector3(0, PODIUM_HEIGHT + 3.0, 0), 96)


func _build_podium() -> void:
	var podium := _cylinder(self, "Podium", PODIUM_RADIUS, PODIUM_HEIGHT, "podium")
	podium.position.y = PODIUM_HEIGHT / 2.0
	for gate: int in GATES:
		var axis: Vector3 = GATES[gate]
		var run: float = PODIUM_RAMP_FOOT - PODIUM_RADIUS
		_ramp(self, "PodiumRamp%d" % gate, axis * PODIUM_RAMP_FOOT, -axis,
				PODIUM_RAMP_WIDTH, run, PODIUM_HEIGHT, PODIUM_RAMP_OVERLAP)


func _build_corridor(gate: int, sealed: bool) -> void:
	var axis: Vector3 = GATES[gate]
	var corridor := Node3D.new()
	corridor.name = "Corridor%d" % gate
	add_child(corridor)
	var length: float = CORRIDOR_END - HUB_RADIUS
	var middle: Vector3 = axis * (HUB_RADIUS + length / 2.0)
	var side: Vector3 = Vector3.UP.cross(axis)
	_box(corridor, "Floor", middle + Vector3.DOWN * 0.05,
			_oriented(axis, Vector3(GATE_WIDTH + 2.0 * WALL, 0.1, length)), "floor", false)
	for sign_value: float in [-1.0, 1.0]:
		_box(corridor, "Wall%s" % ("L" if sign_value < 0 else "R"),
				middle + side * sign_value * (GATE_WIDTH + WALL) / 2.0 + Vector3.UP * GATE_HEIGHT / 2.0,
				_oriented(axis, Vector3(WALL, GATE_HEIGHT, length)), "wall")
	var ceiling := _box(corridor, "Ceiling", middle + Vector3.UP * (GATE_HEIGHT + 0.25),
			_oriented(axis, Vector3(GATE_WIDTH + 2.0 * WALL, 0.5, length)), "ceiling")
	ceiling.add_to_group(&"greybox_ceiling")
	if sealed:
		var end: Vector3 = axis * (CORRIDOR_END + WALL / 2.0) + Vector3.UP * GATE_HEIGHT / 2.0
		_box(corridor, "Seal", end, _oriented(axis, Vector3(GATE_WIDTH, GATE_HEIGHT, WALL)), "wall")
		_label(corridor, "ÁREA %d · interior pendiente" % gate, end - axis + Vector3.UP, 48)


func _build_closed_gate(gate: int) -> void:
	var axis: Vector3 = GATES[gate]
	var center: Vector3 = axis * (HUB_RADIUS + WALL / 2.0) + Vector3.UP * GATE_HEIGHT / 2.0
	var slab := _box(self, "ClosedGate%d" % gate, center,
			_oriented(axis, Vector3(GATE_WIDTH, GATE_HEIGHT, WALL)), "closed")
	slab.add_to_group(&"greybox_closed_gate")
	_label(self, "%d" % gate, center - axis * 0.6, 160)


func _build_room_1() -> void:
	var room := Node3D.new()
	room.name = "Room1"
	add_child(room)
	var size: float = ROOM_HALF * 2.0
	var outer: float = size + 2.0 * WALL
	var near_z: float = ROOM_CENTER_Z + ROOM_HALF
	var far_z: float = ROOM_CENTER_Z - ROOM_HALF
	var wall_y: float = ROOM_CEILING / 2.0
	_box(room, "Floor", Vector3(0, -0.05, ROOM_CENTER_Z), Vector3(outer, 0.1, outer), "floor", false)
	var ceiling := _box(room, "Ceiling", Vector3(0, ROOM_CEILING + 0.25, ROOM_CENTER_Z),
			Vector3(outer, 0.5, outer), "ceiling")
	ceiling.add_to_group(&"greybox_ceiling")
	_box(room, "WallNorth", Vector3(0, wall_y, far_z - WALL / 2.0),
			Vector3(outer, ROOM_CEILING, WALL), "wall")
	for sign_value: float in [-1.0, 1.0]:
		var label: String = "West" if sign_value < 0 else "East"
		_box(room, "Wall" + label,
				Vector3(sign_value * (ROOM_HALF + WALL / 2.0), wall_y, ROOM_CENTER_Z),
				Vector3(WALL, ROOM_CEILING, size), "wall")
		var piece: float = ROOM_HALF - GATE_WIDTH / 2.0
		_box(room, "WallSouth" + label,
				Vector3(sign_value * (GATE_WIDTH / 2.0 + piece / 2.0), wall_y, near_z + WALL / 2.0),
				Vector3(piece, ROOM_CEILING, WALL), "wall")
	_box(room, "Lintel", Vector3(0, (GATE_HEIGHT + ROOM_CEILING) / 2.0, near_z + WALL / 2.0),
			Vector3(GATE_WIDTH, ROOM_CEILING - GATE_HEIGHT, WALL), "wall")
	_box(room, "Deflector", _rect_center(DEFLECTOR, ROOM_CEILING / 2.0),
			Vector3(DEFLECTOR.size.x, ROOM_CEILING, DEFLECTOR.size.y), "block")
	for pillar: String in PILLARS:
		var rect: Rect2 = PILLARS[pillar]
		_box(room, pillar, _rect_center(rect, ROOM_CEILING / 2.0),
				Vector3(rect.size.x, ROOM_CEILING, rect.size.y), "block")
	_box(room, "Platform", _rect_center(PLATFORM, PLATFORM_HEIGHT / 2.0),
			Vector3(PLATFORM.size.x, PLATFORM_HEIGHT, PLATFORM.size.y), "platform")
	var platform_x: float = PLATFORM.position.x + PLATFORM.size.x / 2.0
	var ramp_run: float = RAMP_RA_FOOT_Z - PLATFORM.end.y
	_ramp(room, "RampRA", Vector3(platform_x, 0, RAMP_RA_FOOT_Z), Vector3.FORWARD,
			PLATFORM.size.x, ramp_run, PLATFORM_HEIGHT, 0.0)
	# Número de área visible desde el hub a través de la conexión, sobre la cara del deflector.
	_label(room, "1", Vector3(0, 3.0, DEFLECTOR.end.y + 0.05), 256, false)
	var exit_label := _label(room, "SALIDA ↓ 0", Vector3(0, 5.5, near_z - 0.05), 64, false)
	exit_label.rotation.y = PI


func _build_spawns() -> void:
	var spawns := Node3D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	var index: int = 0
	for data: Dictionary in spawn_transforms():
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % index
		marker.position = data.position
		marker.rotation.y = data.yaw
		marker.add_to_group(&"spawn_points")
		spawns.add_child(marker)
		index += 1


func _build_reserves() -> void:
	var reserves := Node3D.new()
	reserves.name = "DesignReserves"
	add_child(reserves)
	for id: String in RESERVES:
		var marker := Marker3D.new()
		marker.name = id
		marker.position = RESERVES[id]
		marker.add_to_group(&"design_reserve")
		reserves.add_child(marker)
		var mesh := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		var is_tower: bool = id.begins_with("T")
		cylinder.top_radius = 0.8 if is_tower else 0.5
		cylinder.bottom_radius = cylinder.top_radius
		cylinder.height = 1.6 if is_tower else 0.6
		var key: String = "tower" if is_tower else ("health" if id.begins_with("H") else "reserve")
		cylinder.material = _materials[key]
		mesh.mesh = cylinder
		mesh.position.y = cylinder.height / 2.0
		marker.add_child(mesh)
		_label(marker, id + " (reserva)", Vector3(0, cylinder.height + 0.8, 0), 40)


func _box(
	parent: Node, id: String, center: Vector3, size: Vector3, material: String,
	collide: bool = true,
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _materials[material]
	mesh.mesh = box
	body.add_child(mesh)
	if not collide:
		return body
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	return body


func _cylinder(
	parent: Node, id: String, radius: float, height: float, material: String,
	collide: bool = true,
) -> CSGCylinder3D:
	var cylinder := CSGCylinder3D.new()
	cylinder.name = id
	cylinder.radius = radius
	cylinder.height = height
	cylinder.sides = 64
	cylinder.material = _materials[material]
	cylinder.use_collision = collide
	cylinder.collision_layer = 1
	cylinder.collision_mask = 0
	parent.add_child(cylinder)
	return cylinder


## Rampa con pie en `foot` (centro del borde bajo) que sube en dirección `uphill`.
## `overlap` prolonga la parte alta en plano para enrasar con el elemento al que llega.
func _ramp(
	parent: Node, id: String, foot: Vector3, uphill: Vector3, width: float, run: float,
	rise: float, overlap: float,
) -> CSGPolygon3D:
	var ramp := CSGPolygon3D.new()
	ramp.name = id
	var side: Vector3 = uphill.cross(Vector3.UP)
	ramp.basis = Basis(uphill, Vector3.UP, side)
	ramp.position = foot + side * width / 2.0
	ramp.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(run, rise), Vector2(run + overlap, rise), Vector2(run + overlap, 0),
	])
	ramp.depth = width
	ramp.material = _materials["ramp"]
	ramp.use_collision = true
	ramp.collision_layer = 1
	ramp.collision_mask = 0
	parent.add_child(ramp)
	return ramp


func _label(
	parent: Node, text: String, at: Vector3, font_size: int, billboard: bool = true,
) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = font_size
	label.pixel_size = 0.02
	label.outline_size = 12
	label.modulate = Color(1, 0.85, 0.43)
	if billboard:
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label


## Convierte (ancho, alto, largo) de un elemento alineado con `axis` a tamaño en mundo.
static func _oriented(axis: Vector3, size: Vector3) -> Vector3:
	return Vector3(size.z, size.y, size.x) if absf(axis.x) > 0.5 else size


static func _rect_center(rect: Rect2, y: float) -> Vector3:
	var center: Vector2 = rect.get_center()
	return Vector3(center.x, y, center.y)
