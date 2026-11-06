class_name AreaTracker
extends Node
## PUR-032: emite `area_changed` una sola vez por cruce de umbral, sin parpadeo en el borde.
## El nivel (`layout_path`) debe ofrecer `area_at(point, inset) -> int`.

## Distancia que hay que penetrar en el área nueva para aceptarla. Con 1 m, el casco de 2.2 m
## del Runner tiene que estar mayormente dentro; oscilar en el umbral no genera eventos.
const THRESHOLD_MARGIN_M := 1.0

@export var layout_path: NodePath
var areas: Dictionary = {}
@onready var layout: Node = get_node(layout_path)


func _ready() -> void:
	EventBus.runner_respawned.connect(_on_respawned)


func _physics_process(_delta: float) -> void:
	refresh()


func area_of(runner: Runner) -> int:
	return areas.get(runner, -1)


func refresh() -> void:
	for runner: Runner in get_tree().get_nodes_in_group("runners"):
		update_runner(runner)


func update_runner(runner: Runner) -> void:
	var point: Vector3 = runner.global_position
	if not areas.has(runner):
		_set_area(runner, layout.area_at(point, 0.0))
		return
	var candidate: int = layout.area_at(point, THRESHOLD_MARGIN_M)
	if candidate >= 0 and candidate != areas[runner]:
		_set_area(runner, candidate)


func _set_area(runner: Runner, area: int) -> void:
	if areas.get(runner, -2) == area:
		return
	areas[runner] = area
	if area >= 0:
		EventBus.area_changed.emit(runner, area)


func _on_respawned(runner: Runner) -> void:
	# La reaparición es un salto: se acepta el área real sin margen.
	_set_area(runner, layout.area_at(runner.global_position, 0.0))
