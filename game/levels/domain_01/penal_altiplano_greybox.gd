class_name PenalAltiplanoGreybox
extends Node3D
## Greybox del hub + sala 1 del Dominio 1 (PUR-070 rev. 4: escala oficial ×6 en largo).
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
## Variante grande (prueba de escala, 2026-11-06): con `layout_scale` ≥ LARGE_FROM la sala 1 no
## se estira, se llena con un interior propio en coordenadas locales (u = X, d = metros desde la
## entrada hacia el fondo). Medidas en metros reales, no escaladas.
const LARGE_FROM := 3.0
const LARGE_ROOM_CEILING := 12.0
const LARGE_LEDGE_HEIGHT := 3.0
const LARGE_RAMP_RUN := 9.0
## [u0, u1, d0, d1, altura] (altura 0 = hasta el techo).
const LARGE_BLOCKS := [
	[-9, 9, 8, 10, 0],
	[-96, -64, 150, 151, 0], [-48, -8, 150, 151, 0], [8, 48, 150, 151, 0], [64, 96, 150, 151, 0],
	[-33, -31, 151, 170, 0], [-33, -31, 186, 204, 0], [31, 33, 151, 170, 0], [31, 33, 186, 204, 0],
	[-2, 2, 175, 179, 0], [-72, -68, 175, 179, 0], [68, 72, 175, 179, 0],
	[-82, -78, 90, 94, 0], [78, 82, 90, 94, 0], [-82, -78, 134, 138, 0], [78, 82, 134, 138, 0],
	[-60, -44, 100, 101, 1.2], [44, 60, 100, 101, 1.2], [-60, -44, 127, 128, 1.2],
	[44, 60, 127, 128, 1.2], [-78, -62, 114, 115, 1.2], [62, 78, 114, 115, 1.2],
]
## Plataformas a LARGE_LEDGE_HEIGHT: pasarelas perimetrales y plataforma central.
const LARGE_LEDGES := [
	[-108, -96, 24, 216], [96, 108, 24, 216], [-96, 96, 204, 216], [-20, 20, 94, 134],
]
## Rampas: [u_pie, d_pie, dirección cuesta arriba (u, d), ancho].
const LARGE_RAMPS := [
	[-102, 15, Vector2(0, 1), 12], [102, 15, Vector2(0, 1), 12],
	[-40, 195, Vector2(0, 1), 12], [40, 195, Vector2(0, 1), 12],
	[0, 85, Vector2(0, 1), 10], [0, 143, Vector2(0, -1), 10],
	[-29, 114, Vector2(1, 0), 10], [29, 114, Vector2(-1, 0), 10],
]
## Campo de pilares 4 × 4 m alineado: calles rectas de 10 m entre columnas.
const LARGE_PILLAR_ROWS := [34, 48, 62, 76]
const LARGE_PILLAR_STEP := 14.0
const LARGE_PILLAR_HALF := 2.0
const LARGE_PILLAR_SPAN := 77.0
const LARGE_RESERVES := {
	"T1": Vector3(-35, 0, 55), "T2": Vector3(49, 0, 41), "T3": Vector3(0, 0, 160),
	"T4": Vector3(-70, 0, 192), "T5": Vector3(70, 0, 162), "T6": Vector3(35, 0, 100),
	"M1": Vector3(-102, 3, 120), "M2": Vector3(102, 3, 160), "M3": Vector3(0, 3, 114),
	"M4": Vector3(-64, 0, 177), "M5": Vector3(64, 0, 192), "M6": Vector3(-21, 0, 69),
	"H1": Vector3(0, 0, 192), "H2": Vector3(-50, 0, 114),
}
## Ejes cardinales de las compuertas: 1 norte (abierta), 2 este (abierta, sala sin interior),
## 3 sur y 4 oeste (cerradas en R1).
const GATES := {
	1: Vector3(0, 0, -1), 2: Vector3(1, 0, 0), 3: Vector3(0, 0, 1), 4: Vector3(-1, 0, 0),
}

## Escala de planta respecto a las cotas base (rev. 3): multiplica distancias horizontales de
## conexiones y sala; conserva anchos de paso, alturas, pendientes, podio y portal.
## Oficial desde rev. 4: 6.0 (sala de 216 m). Con < LARGE_FROM se construye la sala base de
## 36 m (histórica, solo para comparar). También `--layout-scale=<x>` o PURGA_LAYOUT_SCALE.
@export var layout_scale: float = 6.0
## Escala propia del hub (oficial 3.0 → Ø120 m); ≤ 0 usa layout_scale.
## `--hub-scale=<x>` o PURGA_HUB_SCALE.
@export var hub_scale: float = 3.0
var room_ceiling: float = ROOM_CEILING
var hub_radius: float = HUB_RADIUS
var corridor_end: float = CORRIDOR_END
var room_half: float = ROOM_HALF
var room_center_z: float = ROOM_CENTER_Z
var _materials: Dictionary = {}


func _ready() -> void:
	if OS.has_environment("PURGA_LAYOUT_SCALE"):
		layout_scale = OS.get_environment("PURGA_LAYOUT_SCALE").to_float()
	if OS.has_environment("PURGA_HUB_SCALE"):
		hub_scale = OS.get_environment("PURGA_HUB_SCALE").to_float()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--layout-scale="):
			layout_scale = arg.get_slice("=", 1).to_float()
		elif arg.begins_with("--hub-scale="):
			hub_scale = arg.get_slice("=", 1).to_float()
	if hub_scale <= 0.0:
		hub_scale = layout_scale
	if is_large():
		room_ceiling = LARGE_ROOM_CEILING
	hub_radius = PODIUM_RAMP_FOOT + 0.5 + (HUB_RADIUS - PODIUM_RAMP_FOOT - 0.5) * _hub_stretch()
	corridor_end = hub_radius + (CORRIDOR_END - HUB_RADIUS) * layout_scale
	room_half = ROOM_HALF * layout_scale
	room_center_z = -(corridor_end + room_half)
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


## Lleva un punto X/Z de la ficha (escala 1) a la planta escalada. El podio y su anillo
## de spawns no cambian; el resto del hub se estira radialmente; las conexiones se alargan
## sin ensancharse; la sala se escala desde su centro.
func map_point(point: Vector2) -> Vector2:
	if point.y < -CORRIDOR_END:
		return Vector2(point.x * layout_scale,
				room_center_z + (point.y - ROOM_CENTER_Z) * layout_scale)
	var radius: float = point.length()
	if radius > HUB_RADIUS:
		var along_x: bool = absf(point.x) > absf(point.y)
		var reach: float = absf(point.x) if along_x else absf(point.y)
		var mapped: float = hub_radius + (reach - HUB_RADIUS) * layout_scale
		if along_x:
			return Vector2(signf(point.x) * mapped, point.y)
		return Vector2(point.x, signf(point.y) * mapped)
	var core: float = PODIUM_RAMP_FOOT + 0.5
	if radius > core:
		return point * (core + (radius - core) * _hub_stretch()) / radius
	return point


func map_rect(rect: Rect2, keep_depth: bool = false, keep_size: bool = false) -> Rect2:
	var center: Vector2 = map_point(rect.get_center())
	var size: Vector2 = rect.size
	if not keep_size:
		size.x *= layout_scale
		if not keep_depth:
			size.y *= layout_scale
	return Rect2(center - size / 2.0, size)


func _hub_stretch() -> float:
	var core: float = PODIUM_RAMP_FOOT + 0.5
	var scale_value: float = hub_scale if hub_scale > 0.0 else layout_scale
	return (HUB_RADIUS * scale_value - core) / (HUB_RADIUS - core)


func is_large() -> bool:
	return layout_scale >= LARGE_FROM


## Punto local de la sala 1 (u = X, d = metros desde la entrada) en X/Z del mundo.
func room_point(u: float, d: float) -> Vector2:
	return Vector2(u, -corridor_end - d)


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
	var margin: float = 6.0
	var far_z: float = room_center_z - room_half - margin
	var near_z: float = hub_radius + margin
	box.size = Vector3(2.0 * (corridor_end + margin), 1.0, near_z - far_z)
	shape.shape = box
	shape.position = Vector3(0, -0.5, (near_z + far_z) / 2.0)
	ground.add_child(shape)
	add_child(ground)


func _build_hub() -> void:
	var hub := Node3D.new()
	hub.name = "Hub"
	add_child(hub)
	var floor_disc := _cylinder(hub, "Floor", hub_radius + HUB_WALL, 0.1, "hub", false)
	floor_disc.position.y = 0.0
	var wall := CSGCombiner3D.new()
	wall.name = "Wall"
	wall.use_collision = true
	hub.add_child(wall)
	var outer := _cylinder(wall, "Outer", hub_radius + HUB_WALL, HUB_CEILING, "wall", false)
	outer.position.y = HUB_CEILING / 2.0
	var inner := _cylinder(wall, "Inner", hub_radius, HUB_CEILING + 0.2, "wall", false)
	inner.position.y = HUB_CEILING / 2.0
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	for gate: int in GATES:
		var axis: Vector3 = GATES[gate]
		var cut := CSGBox3D.new()
		cut.name = "Gate%d" % gate
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		cut.size = _oriented(axis, Vector3(GATE_WIDTH, GATE_HEIGHT, 4.0))
		cut.position = axis * (hub_radius + 0.5) + Vector3.UP * GATE_HEIGHT / 2.0
		wall.add_child(cut)
	var ceiling := CSGCombiner3D.new()
	ceiling.name = "Ceiling"
	ceiling.use_collision = true
	ceiling.add_to_group(&"greybox_ceiling")
	hub.add_child(ceiling)
	var slab := _cylinder(ceiling, "Slab", hub_radius + HUB_WALL, 0.5, "ceiling", false)
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
	var length: float = corridor_end - hub_radius
	var middle: Vector3 = axis * (hub_radius + length / 2.0)
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
		var end: Vector3 = axis * (corridor_end + WALL / 2.0) + Vector3.UP * GATE_HEIGHT / 2.0
		_box(corridor, "Seal", end, _oriented(axis, Vector3(GATE_WIDTH, GATE_HEIGHT, WALL)), "wall")
		_label(corridor, "ÁREA %d · interior pendiente" % gate, end - axis + Vector3.UP, 48)


func _build_closed_gate(gate: int) -> void:
	var axis: Vector3 = GATES[gate]
	var center: Vector3 = axis * (hub_radius + WALL / 2.0) + Vector3.UP * GATE_HEIGHT / 2.0
	var slab := _box(self, "ClosedGate%d" % gate, center,
			_oriented(axis, Vector3(GATE_WIDTH, GATE_HEIGHT, WALL)), "closed")
	slab.add_to_group(&"greybox_closed_gate")
	_label(self, "%d" % gate, center - axis * 0.6, 160)


func _build_room_1() -> void:
	var room := Node3D.new()
	room.name = "Room1"
	add_child(room)
	var size: float = room_half * 2.0
	var outer: float = size + 2.0 * WALL
	var near_z: float = room_center_z + room_half
	var far_z: float = room_center_z - room_half
	var wall_y: float = room_ceiling / 2.0
	_box(room, "Floor", Vector3(0, -0.05, room_center_z), Vector3(outer, 0.1, outer), "floor", false)
	var ceiling := _box(room, "Ceiling", Vector3(0, room_ceiling + 0.25, room_center_z),
			Vector3(outer, 0.5, outer), "ceiling")
	ceiling.add_to_group(&"greybox_ceiling")
	_box(room, "WallNorth", Vector3(0, wall_y, far_z - WALL / 2.0),
			Vector3(outer, room_ceiling, WALL), "wall")
	for sign_value: float in [-1.0, 1.0]:
		var label: String = "West" if sign_value < 0 else "East"
		_box(room, "Wall" + label,
				Vector3(sign_value * (room_half + WALL / 2.0), wall_y, room_center_z),
				Vector3(WALL, room_ceiling, size), "wall")
		var piece: float = room_half - GATE_WIDTH / 2.0
		_box(room, "WallSouth" + label,
				Vector3(sign_value * (GATE_WIDTH / 2.0 + piece / 2.0), wall_y, near_z + WALL / 2.0),
				Vector3(piece, room_ceiling, WALL), "wall")
	_box(room, "Lintel", Vector3(0, (GATE_HEIGHT + room_ceiling) / 2.0, near_z + WALL / 2.0),
			Vector3(GATE_WIDTH, room_ceiling - GATE_HEIGHT, WALL), "wall")
	if is_large():
		_build_room_1_large(room)
		var large_exit := _label(room, "SALIDA ↓ 0", Vector3(0, 7.0, near_z - 0.05), 96, false)
		large_exit.rotation.y = PI
		return
	var deflector: Rect2 = map_rect(DEFLECTOR, true)
	_box(room, "Deflector", _rect_center(deflector, room_ceiling / 2.0),
			Vector3(deflector.size.x, room_ceiling, deflector.size.y), "block")
	for pillar: String in PILLARS:
		var rect: Rect2 = map_rect(PILLARS[pillar], false, true)
		_box(room, pillar, _rect_center(rect, room_ceiling / 2.0),
				Vector3(rect.size.x, room_ceiling, rect.size.y), "block")
	var platform: Rect2 = map_rect(PLATFORM)
	_box(room, "Platform", _rect_center(platform, PLATFORM_HEIGHT / 2.0),
			Vector3(platform.size.x, PLATFORM_HEIGHT, platform.size.y), "platform")
	var platform_x: float = platform.position.x + platform.size.x / 2.0
	var ramp_run: float = RAMP_RA_FOOT_Z - PLATFORM.end.y
	_ramp(room, "RampRA", Vector3(platform_x, 0, platform.end.y + ramp_run), Vector3.FORWARD,
			platform.size.x, ramp_run, PLATFORM_HEIGHT, 0.0)
	# Número de área visible desde el hub a través de la conexión, sobre la cara del deflector.
	_label(room, "1", Vector3(0, 3.0, deflector.end.y + 0.05), 256, false)
	var exit_label := _label(room, "SALIDA ↓ 0", Vector3(0, 5.5, near_z - 0.05), 64, false)
	exit_label.rotation.y = PI


func _build_room_1_large(room: Node3D) -> void:
	var index: int = 0
	for block: Array in LARGE_BLOCKS:
		var height: float = block[4] if block[4] > 0.0 else room_ceiling
		var material: String = "block" if block[4] > 0.0 or index == 0 else "wall"
		_local_box(room, "Deflector" if index == 0 else "Block%d" % index,
				block[0], block[1], block[2], block[3], height, material)
		index += 1
	index = 0
	for ledge: Array in LARGE_LEDGES:
		_local_box(room, "Ledge%d" % index, ledge[0], ledge[1], ledge[2], ledge[3],
				LARGE_LEDGE_HEIGHT, "platform")
		index += 1
	index = 0
	for ramp: Array in LARGE_RAMPS:
		var foot: Vector2 = room_point(ramp[0], ramp[1])
		var direction: Vector2 = ramp[2]
		var uphill := Vector3(direction.x, 0, -direction.y)
		_ramp(room, "LargeRamp%d" % index, Vector3(foot.x, 0, foot.y), uphill, ramp[3],
				LARGE_RAMP_RUN, LARGE_LEDGE_HEIGHT, 0.0)
		index += 1
	for d: float in LARGE_PILLAR_ROWS:
		var u: float = -LARGE_PILLAR_SPAN
		while u <= LARGE_PILLAR_SPAN + 0.1:
			var half: float = LARGE_PILLAR_HALF
			_local_box(room, "Pillar_%d_%d" % [u, d], u - half, u + half, d - half, d + half,
					room_ceiling, "block")
			u += LARGE_PILLAR_STEP
	var face: Vector2 = room_point(0, 8)
	_label(room, "1", Vector3(face.x, 4.0, face.y + 0.05), 384, false)


func _local_box(
	parent: Node, id: String, u0: float, u1: float, d0: float, d1: float, height: float,
	material: String,
) -> void:
	var center: Vector2 = room_point((u0 + u1) / 2.0, (d0 + d1) / 2.0)
	_box(parent, id, Vector3(center.x, height / 2.0, center.y),
			Vector3(u1 - u0, height, d1 - d0), material)


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
	var table: Dictionary = LARGE_RESERVES if is_large() else RESERVES
	for id: String in table:
		var marker := Marker3D.new()
		marker.name = id
		var source: Vector3 = table[id]
		var flat: Vector2 = (room_point(source.x, source.z) if is_large()
				else map_point(Vector2(source.x, source.z)))
		marker.position = Vector3(flat.x, source.y, flat.y)
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
