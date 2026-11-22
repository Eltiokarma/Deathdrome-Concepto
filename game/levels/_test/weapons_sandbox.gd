extends Node3D
## Campo jugable de secundarias; --weapons-preview reproduce cuatro pruebas visuales.

const RUNNER := preload("res://entities/runner/runner.tscn")
const PICKUP := preload("res://entities/pickups/pickup.tscn")
# Blanco 1 fuera de la onda/torres y del cono del laser en la ultima demostracion.
const TARGET_SPOTS := [Vector3(-4, 0.1, -22), Vector3(16, 0.1, -10),
		Vector3(-22, 0.1, 4), Vector3(-18, 0.1, 4)]
var runner: Runner
var targets: Array[Runner] = []
var towers: Array[FusionTower] = []
var preview: bool = false
var preview_events: Dictionary = {}
var _time: float = 0.0
var _stage: int = -1
var _title := Label.new()
var _status := Label.new()
var _camera := Camera3D.new()


func _ready() -> void:
	preview = "--weapons-preview" in OS.get_cmdline_user_args()
	_build_arena()
	_build_ui()
	runner = _runner("Jugador", Vector3(0, 0.1, 18))
	for index: int in range(TARGET_SPOTS.size()):
		var target: Runner = _runner("Blanco%d" % (index + 1), TARGET_SPOTS[index])
		target.controller = null
		target.get_node("RunnerCamera").set_physics_process(false)
		targets.append(target)
	for point: Vector3 in [Vector3(8, 0, -7), Vector3(14, 0, -7)]:
		var tower := FusionTower.new()
		add_child(tower)
		tower.position = point
		towers.append(tower)
	for index: int in range(2):
		var pickup: Pickup = PICKUP.instantiate()
		pickup.weapon_id = &"missile" if index == 0 else &"shockwave"
		add_child(pickup)
		pickup.position = Vector3(-4 + index * 8, 0, 18)
		pickup.collection_enabled = not preview
	_refill()
	EventBus.secondary_fired.connect(_on_fired)
	EventBus.fusion_tower_detonated.connect(_on_tower)
	add_child(_camera)
	if preview:
		start_preview()
	else:
		runner.get_node("RunnerCamera/SpringArm3D/Camera3D").make_current()


func _physics_process(delta: float) -> void:
	if not preview or get_tree().paused:
		return
	_time += delta
	runner.input_frame = InputFrame.new()
	targets[3].input_frame = InputFrame.new()
	if _time < 4.0:
		if _stage != 0:
			_stage = 0
			_title.text = "1 · MISIL: FIJACIÓN Y DAÑO DIRECTO"
		if _time >= 1.0 and not preview_events.has("missile"):
			runner.input_frame.secondary = runner.missile_lock.locked_target() != null
	elif _time < 8.0:
		if _stage != 1:
			_stage = 1
			_prepare_player(Vector3(3, 0.1, -7), &"shockwave")
			_title.text = "2 · ONDA: DETONACIÓN DE TORRES EN CADENA"
			_set_view(Vector3(8, 0, -5))
		if _time >= 4.7 and not preview_events.has("shockwave"):
			runner.input_frame.secondary = true
	elif _time < 12.0:
		if _stage != 2:
			_stage = 2
			_prepare_player(Vector3(-20, 0.1, 10), &"shockwave")
			_title.text = "3 · SALTAR EVITA LA ONDA"
			_set_view(Vector3(-19, 0, 5))
		if _time >= 9.0 and not preview_events.has("jump"):
			targets[3].input_frame.jump = true
			preview_events["jump"] = true
		if _time >= 9.45 and not preview_events.has("jump_wave"):
			runner.input_frame.secondary = true
			preview_events["jump_wave"] = true
	elif _time < 16.0:
		if _stage != 3:
			_stage = 3
			_prepare_player(Vector3(8, 0.1, 10), &"missile")
			for tower: FusionTower in towers:
				tower.reset()
			_title.text = "4 · LÁSER: USA LAS TORRES DEL ESCENARIO"
			_set_view(Vector3(8, 0, -3))
		runner.input_frame.laser = _time >= 12.7 and _time < 13.1
	elif _stage != 4:
		_stage = 4
		_title.text = "PRUEBA COMPLETA · MISIL / ONDA / TORRES"
		preview_events["missile_damage"] = targets[0].health.maximum - targets[0].health.current
		preview_events["ground_damage"] = targets[2].health.maximum - targets[2].health.current
		preview_events["jumper_damage"] = targets[3].health.maximum - targets[3].health.current
		print("WEAPONS_PREVIEW %s" % JSON.stringify(preview_events))


func _process(_delta: float) -> void:
	if runner == null:
		return
	var selected: String = str(runner.inventory.selected_weapon()).to_upper()
	var text: String = "INTEGRIDAD %.0f · CARGAS %d · %s" % [runner.health.current,
			runner.inventory.slots.size(), selected]
	if runner.missile_lock.target != null:
		text += " · FIJACIÓN %d %%" % roundi(runner.missile_lock.progress * 100.0)
	for index: int in range(targets.size()):
		text += "\nBLANCO %d · %.0f / %.0f PI" % [index + 1,
				targets[index].health.current, targets[index].health.maximum]
	_status.text = text


func _runner(id: String, point: Vector3) -> Runner:
	var result: Runner = RUNNER.instantiate()
	result.name = id
	result.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(result)
	result.reset_at(point)
	var label := Label3D.new()
	label.text = id
	label.font_size = 36
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.0
	result.add_child(label)
	return result


func start_preview() -> void:
	preview = true
	runner.controller = null
	for pickup: Pickup in get_tree().get_nodes_in_group("pickups"):
		if is_ancestor_of(pickup):
			pickup.collection_enabled = false
	_camera.make_current()
	_set_view(Vector3(0, 0, -2))


func _prepare_player(point: Vector3, weapon: StringName) -> void:
	runner.reset_at(point)
	runner.controller = null
	runner.inventory.add(weapon)


func _refill() -> void:
	runner.inventory.clear()
	runner.inventory.add(&"missile")
	runner.inventory.add(&"shockwave")
	runner.inventory.add(&"missile")


func _on_fired(shooter: Runner, weapon: StringName) -> void:
	if preview and shooter == runner:
		preview_events[str(weapon)] = preview_events.get(str(weapon), 0) + 1


func _on_tower(tower: Node3D, _source: Runner) -> void:
	if preview and tower in towers:
		preview_events["towers"] = preview_events.get("towers", 0) + 1


func _set_view(focus: Vector3) -> void:
	_camera.position = focus + Vector3(23, 24, 34)
	_camera.look_at(focus)


func _build_arena() -> void:
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.035, 0.05, 0.075)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.65, 0.75, 0.9)
	sky.ambient_light_energy = 0.8
	environment.environment = sky
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	add_child(sun)
	_box(Vector3(0, -0.5, 0), Vector3(70, 1, 70), Color(0.13, 0.18, 0.23))
	_box(Vector3(-28, 1.5, -14), Vector3(10, 3, 1), Color(0.3, 0.4, 0.45))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(side * 35, 1.5, 0), Vector3(1, 3, 70), Color(0.25, 0.3, 0.35))
		_box(Vector3(0, 1.5, side * 35), Vector3(70, 3, 1), Color(0.25, 0.3, 0.35))


func _box(point: Vector3, size: Vector3, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	body.position = point
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	box.material = material
	mesh.mesh = box
	body.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(_title)
	_title.position = Vector2(24, 18)
	_title.add_theme_font_size_override("font_size", 24)
	_title.text = "CAMPO DE ARMAS · MISIL / ONDA / TORRES"
	var help := Label.new()
	layer.add_child(help)
	help.position = Vector2(24, 54)
	help.text = "WASD: conducir · Espacio: salto · J/clic: láser · K/clic derecho: secundaria\n" + (
			"Q/E: selección · R: reiniciar · F7: volver · Esc: pausa · Cargas junto al inicio")
	layer.add_child(_status)
	_status.position = Vector2(24, 104)
	_status.add_theme_font_size_override("font_size", 18)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://levels/_test/driving_sandbox.tscn")
	elif event.is_action_pressed("reset_runner"):
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
