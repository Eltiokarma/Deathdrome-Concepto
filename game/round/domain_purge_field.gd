class_name DomainPurgeField
extends PurgeField
## PUR-034 en un dominio con salas: un frente por área, desde el muro de fondo de la sala
## hasta el umbral del hub, y después el cierre radial del hub (lógica heredada).
## Las áreas con compuerta cerrada son letales desde el inicio: no hay refugios.
## El nivel (`layout_path`) debe ofrecer `area_at`, `area_far_edge`, `is_gate_open`,
## `hub_radius`, `room_half` y `GATES`.

@export var layout_path: NodePath
## Metros recorridos por los frentes desde el comienzo de la Purga.
var travel: float = 0.0
var _fronts: Dictionary = {}
@onready var layout: Node = get_node(layout_path)


func _ready() -> void:
	super._ready()
	for gate: int in layout.GATES:
		var front := MeshInstance3D.new()
		front.name = "Front%d" % gate
		var box := BoxMesh.new()
		box.size = Vector3(1, 1, 1)
		front.mesh = box
		front.material_override = $Wall.material_override
		front.visible = false
		add_child(front)
		_fronts[gate] = front


func reset() -> void:
	super.reset()
	hub_radius = layout.hub_radius if layout != null else hub_radius
	radius = hub_radius
	travel = 0.0
	for front: MeshInstance3D in _fronts.values():
		front.visible = false


## Distancia al centro del hub a la que está el frente de cada sala.
func front_along() -> float:
	return maxf(layout.hub_radius, layout.area_far_edge() - travel)


func max_travel() -> float:
	return layout.area_far_edge() - layout.hub_radius


func contains(point: Vector3) -> bool:
	if radius <= 0.0:
		return true
	var area: int = layout.area_at(point, 0.0)
	if area < 0:
		return true
	if area == 0:
		return Vector2(point.x, point.z).length() >= radius
	if not layout.is_gate_open(area):
		return true
	return point.dot(layout.GATES[area]) >= front_along()


func _advance(delta: float, speed: float) -> void:
	var remaining: float = delta
	if travel < max_travel():
		var used: float = minf(remaining, (max_travel() - travel) / speed)
		travel = minf(max_travel(), travel + speed * used)
		remaining -= used
	if remaining > 0.0:
		radius = maxf(0.0, radius - remaining * hub_radius / Balance.get_f("purge.hub_close_s"))
	_update_fronts()


func _update_fronts() -> void:
	var along: float = front_along()
	for gate: int in _fronts:
		var front: MeshInstance3D = _fronts[gate]
		var axis: Vector3 = layout.GATES[gate]
		front.visible = travel < max_travel() and layout.is_gate_open(gate)
		var width: float = 2.0 * layout.room_half
		front.position = axis * along + Vector3.UP * visual_height * 0.5
		front.scale = Vector3(width, visual_height, 0.5)
		if absf(axis.x) > 0.5:
			front.scale = Vector3(0.5, visual_height, width)
