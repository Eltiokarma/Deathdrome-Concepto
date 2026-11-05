class_name Runner
extends CharacterBody3D
## Coordina stats, controlador y componentes. No consulta Input ni aplica daño.

@export var runner_id: StringName = &"amaru"
var stats: RunnerStats
var current_integrity: float:
	get:
		return health.current if health != null else 0.0
var input_frame := InputFrame.new()
var last_input := InputFrame.new()
var controller: PlayerInput

@onready var health: HealthComponent = $HealthComponent
@onready var barrier: BarrierWeapon = $BarrierWeapon
@onready var laser: LaserWeapon = $LaserWeapon
@onready var motor: RunnerMotor = $RunnerMotor
@onready var model: Node3D = $Model


func _ready() -> void:
	add_to_group("runners")
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
	if health != null:
		health.reset(stats.max_integrity)
	if barrier != null:
		barrier.reset()
	if model != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = stats.color
		material.roughness = 0.7
		$Model/Body.material_override = material


func _physics_process(delta: float) -> void:
	health.tick(delta)
	if health.destroyed:
		velocity = Vector3.ZERO
		model.hide()
		set_collision_layer_value(2, false)
		barrier.tick(delta, false)
		laser.tick(delta, false)
		return
	var frame: InputFrame = controller.sample() if controller != null else input_frame
	last_input = frame.sanitized()
	motor.step(self, last_input, delta)
	for index: int in range(get_slide_collision_count()):
		var segment := get_slide_collision(index).get_collider() as BarrierSegment
		if segment != null:
			segment.hit(self)
	barrier.tick(delta, last_input.barrier)
	laser.tick(delta, last_input.laser)


func reset_at(point: Vector3, yaw: float = 0.0) -> void:
	global_position = point
	rotation = Vector3(0, yaw, 0)
	velocity = Vector3.ZERO
	input_frame = InputFrame.new()
	last_input = InputFrame.new()
	motor.reset()
	health.reset(stats.max_integrity)
	laser.reset()
	barrier.reset()
	set_collision_layer_value(2, true)
	model.visible = ($RunnerCamera as RunnerCamera).mode != 2
