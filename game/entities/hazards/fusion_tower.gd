class_name FusionTower
extends StaticBody3D
## Torre de escenario: se descarga una vez, propaga cadenas y se recarga con Balance.

const BODY_RADIUS_M := 0.8
const BODY_HEIGHT_M := 1.6
const CONTACT_MARGIN_M := 0.05
var charged: bool = true
var recharge_left: float = 0.0
var enabled: bool = true:
	set(value):
		enabled = value
		if not value:
			_clear_chain()
var _chain_left: float = -1.0
var _chain_source: WeakRef
var _chain_life: int = -1
var _material := StandardMaterial3D.new()
var _label := Label3D.new()
var _contact := Area3D.new()


func _ready() -> void:
	add_to_group("fusion_towers")
	collision_layer = 1
	collision_mask = 0
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = BODY_RADIUS_M
	cylinder.bottom_radius = BODY_RADIUS_M
	cylinder.height = BODY_HEIGHT_M
	cylinder.radial_segments = 12
	var mesh := MeshInstance3D.new()
	mesh.mesh = cylinder
	mesh.material_override = _material
	mesh.position.y = BODY_HEIGHT_M * 0.5
	add_child(mesh)
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var shape := CylinderShape3D.new()
	shape.radius = BODY_RADIUS_M
	shape.height = BODY_HEIGHT_M
	collider.shape = shape
	collider.position = mesh.position
	add_child(collider)
	_contact.name = "Contact"
	_contact.collision_layer = 0
	_contact.collision_mask = 2
	_contact.monitorable = false
	var contact_shape := CollisionShape3D.new()
	var shell: CylinderShape3D = shape.duplicate() as CylinderShape3D
	shell.radius += CONTACT_MARGIN_M
	contact_shape.shape = shell
	contact_shape.position = mesh.position
	_contact.add_child(contact_shape)
	add_child(_contact)
	_contact.body_entered.connect(_on_body_entered)
	_label.position.y = BODY_HEIGHT_M + 0.6
	_label.font_size = 32
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	_update_visual()


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not enabled or get_tree().paused or not is_finite(delta) or delta < 0.0:
		return
	if not charged:
		recharge_left = maxf(0.0, recharge_left - delta)
		if recharge_left <= 0.0:
			charged = true
			_update_visual()
	elif _chain_left >= 0.0:
		_chain_left = maxf(0.0, _chain_left - delta)
		if _chain_left <= 0.0:
			var source: Runner = _chain_source.get_ref() as Runner if _chain_source != null else null
			if source != null and source.health.life_id != _chain_life:
				source = null
			_clear_chain()
			trigger(source)
	if charged:
		for body: Node3D in _contact.get_overlapping_bodies():
			var runner: Runner = body as Runner
			if runner != null and not runner.health.destroyed and trigger(runner):
				break


func trigger(source: Runner = null) -> bool:
	if not enabled or not charged or get_tree().paused:
		return false
	if not is_instance_valid(source):
		source = null
	if is_instance_valid(source) and source.health.in_safe_zone:
		return false
	if BlastDamage.in_safe_zone(self, global_position):
		return false
	charged = false
	recharge_left = Balance.get_f("hazards.fusion_tower.recharge_s")
	_clear_chain()
	_update_visual()
	EventBus.fusion_tower_detonated.emit(self, source)
	BlastDamage.apply(self, source, &"tower")
	return true


func queue_chain(source: Runner = null) -> void:
	if not enabled or not charged or _chain_left >= 0.0:
		return
	_chain_left = Balance.get_f("hazards.fusion_tower.chain_delay_s")
	_chain_source = weakref(source) if is_instance_valid(source) else null
	_chain_life = source.health.life_id if is_instance_valid(source) else -1


func reset() -> void:
	charged = true
	recharge_left = 0.0
	_clear_chain()
	_update_visual()


func _clear_chain() -> void:
	_chain_left = -1.0
	_chain_source = null
	_chain_life = -1


func _on_body_entered(body: Node3D) -> void:
	var runner: Runner = body as Runner
	if runner != null and not runner.health.destroyed:
		trigger(runner)


func _update_visual() -> void:
	_material.albedo_color = Color(1.0, 0.55, 0.1) if charged else Color(0.12, 0.14, 0.16)
	_material.emission_enabled = charged
	_material.emission = Color(1.0, 0.25, 0.05)
	_label.text = "TORRE CARGADA" if charged else "TORRE DESCARGADA"
