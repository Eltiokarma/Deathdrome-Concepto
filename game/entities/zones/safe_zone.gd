class_name SafeZone
extends Node3D
## Volumen cilíndrico consultado al disparar/recibir daño: sin retraso de body_entered.

@export var radius: float = 20.0
@export var height: float = 12.0
@export var manager_path: NodePath
@export_enum("balance", "always", "round_start", "off") var policy: String = "balance"
var manager: RoundManager
var _material := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("safe_zones")
	if not manager_path.is_empty():
		manager = get_node_or_null(manager_path) as RoundManager
	var circle := CylinderMesh.new()
	circle.top_radius = radius
	circle.bottom_radius = radius
	circle.height = 0.03
	circle.radial_segments = 64
	$Floor.mesh = circle
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	$Floor.material_override = _material


func active() -> bool:
	var mode: String = Balance.get_s("round.hub_safe_mode") if policy == "balance" else policy
	if mode == "always":
		return true
	if mode != "round_start" or not is_instance_valid(manager):
		return false
	if manager.state in [RoundManager.State.INTRO, RoundManager.State.COUNTDOWN]:
		return true
	return manager.state == RoundManager.State.PLAYING and (
		Balance.get_f("round.duration_s") - manager.seconds_left
		< Balance.get_f("round.hub_safe_round_start_s")
	)


func protects(runner: Runner) -> bool:
	if not active() or not is_instance_valid(runner):
		return false
	var point: Vector3 = to_local(runner.global_position)
	return Vector2(point.x, point.z).length_squared() <= radius * radius and (
		absf(point.y) <= height * 0.5
	)


func _process(_delta: float) -> void:
	var enabled: bool = active()
	_material.albedo_color = Color(0.1, 0.8, 0.65, 0.25) if enabled else Color(0.4, 0.4, 0.4, 0.12)
	$Label.text = "ZONA FRANCA" if enabled else "ZONA FRANCA / INACTIVA"
