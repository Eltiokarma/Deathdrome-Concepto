class_name RunnerCamera
extends Node3D
## Seguimiento visual; SpringArm hace barrido contra mundo y barreras.

var mode: int = 0
var _yaw: float = 0.0
@onready var runner: Runner = get_parent() as Runner
@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	if not runner.is_node_ready():
		await runner.ready
	top_level = true
	_yaw = runner.rotation.y
	arm.add_excluded_object(runner.get_rid())
	_apply_mode()


func _physics_process(delta: float) -> void:
	if runner.last_input.cycle_camera:
		mode = (mode + 1) % 3
		_apply_mode()
	var target_yaw: float = runner.rotation.y + (PI if runner.last_input.look_back else 0.0)
	var weight: float = 1.0 - exp(-Balance.get_f("camera.turn_response") * delta)
	_yaw = lerp_angle(_yaw, target_yaw, weight)
	global_position = runner.global_position + Vector3.UP * Balance.get_f(_key("height_m"))
	global_rotation = Vector3(0, _yaw, 0)


func _key(field: String) -> String:
	return "camera.%s.%s" % [["near", "far", "cockpit"][mode], field]


func _apply_mode() -> void:
	arm.spring_length = Balance.get_f(_key("distance_m"))
	camera.fov = Balance.get_f("camera.fov_vertical_deg")
	camera.rotation.x = deg_to_rad(Balance.get_f(_key("pitch_deg")))
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	# Evita mirar desde dentro de la malla del propio vehículo.
	runner.model.visible = mode != 2
