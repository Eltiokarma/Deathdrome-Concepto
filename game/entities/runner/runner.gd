class_name Runner
extends CharacterBody3D
## Coordina stats, controlador y componentes. No consulta Input ni aplica daño.

@export var runner_id: StringName = &"amaru"
var stats: RunnerStats
var current_integrity: float = 0.0
var input_frame := InputFrame.new()
var last_input := InputFrame.new()
var controller: PlayerInput

@onready var motor: RunnerMotor = $RunnerMotor
@onready var model: Node3D = $Model


func _ready() -> void:
	controller = get_node_or_null("PlayerInput") as PlayerInput
	setup(runner_id)
	floor_max_angle = deg_to_rad(Balance.get_f("movement.floor_max_angle_deg"))
	floor_snap_length = Balance.get_f("movement.floor_snap_m")
	floor_constant_speed = true


func setup(id: StringName) -> void:
	var next: RunnerStats = Balance.runner(id)
	if next == null:
		return
	runner_id = id
	stats = next
	current_integrity = stats.max_integrity
	if model != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = stats.color
		material.roughness = 0.7
		$Model/Body.material_override = material


func _physics_process(delta: float) -> void:
	var frame: InputFrame = controller.sample() if controller != null else input_frame
	last_input = frame.sanitized()
	motor.step(self, last_input, delta)


func reset_at(point: Vector3, yaw: float = 0.0) -> void:
	global_position = point
	rotation = Vector3(0, yaw, 0)
	velocity = Vector3.ZERO
	input_frame = InputFrame.new()
	last_input = InputFrame.new()
	motor.reset()
