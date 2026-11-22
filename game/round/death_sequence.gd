class_name DeathSequence
extends Node
## PUR-023: al destruirse un Runner deja una pira y eyecta a su piloto, que huye del atacante.
## Las muertes por Purga no eyectan piloto (no hay a dónde huir ni reaparición).

const PILOT_SCENE := preload("res://entities/pilot/pilot.tscn")

@export var spawn_parent_path: NodePath = NodePath("..")
@onready var spawn_parent: Node = get_node(spawn_parent_path)


func _ready() -> void:
	EventBus.runner_destroyed.connect(_on_destroyed)


func _on_destroyed(victim: Runner, killer: Runner, weapon: StringName) -> void:
	if not is_instance_valid(victim):
		return
	var pyre := Pyre.new()
	spawn_parent.add_child(pyre)
	pyre.global_position = victim.global_position
	if weapon == &"purge":
		return
	var away: Vector3 = -victim.global_basis.z
	if is_instance_valid(killer) and killer != victim:
		away = victim.global_position - killer.global_position
	var pilot: Pilot = PILOT_SCENE.instantiate()
	spawn_parent.add_child(pilot)
	pilot.setup(victim, victim.global_position, away)
	EventBus.pilot_ejected.emit(pilot, victim)
