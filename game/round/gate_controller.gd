class_name GateController
extends Node
## PUR-036: abre las compuertas de las áreas de `round.open_areas_by_round` al empezar cada
## ronda; las demás quedan cerradas (losa sólida y luz roja). El nivel (`layout_path`) debe
## ofrecer `set_gate_open(gate, open)` e `is_gate_open(gate)`.

const GATE_COUNT := 4

@export var layout_path: NodePath
@onready var layout: Node = get_node(layout_path)


func _ready() -> void:
	EventBus.round_intro_started.connect(_on_round_intro)


static func open_areas(round_index: int) -> Array:
	var table: Array = Balance.get_a("round.open_areas_by_round")
	var open: Array = []
	for area: Variant in table[clampi(round_index, 1, table.size()) - 1]:
		open.append(int(area))
	return open


func apply_round(round_index: int) -> void:
	var open: Array = open_areas(round_index)
	for gate: int in range(1, GATE_COUNT + 1):
		layout.set_gate_open(gate, gate in open)


func _on_round_intro(_domain_id: int, round_index: int, _quota: int) -> void:
	apply_round(round_index)
