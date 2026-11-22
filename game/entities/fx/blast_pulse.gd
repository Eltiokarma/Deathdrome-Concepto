class_name BlastPulse
extends Node3D
## Pulso visual original, sin colision ni temporizacion de dano.

const DURATION_S := 0.35
var _elapsed: float = 0.0
var _radius: float = 1.0
var _height: float = 1.0
var _material := StandardMaterial3D.new()
var _mesh := MeshInstance3D.new()


func _ready() -> void:
	add_to_group("weapon_effects")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_mesh)


func setup(radius: float, height: float, tint: Color) -> void:
	_radius = radius
	_height = height
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.0
	cylinder.height = 1.0
	cylinder.radial_segments = 32
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(tint, 0.35)
	_mesh.mesh = cylinder
	_mesh.material_override = _material
	_mesh.position.y = height * 0.5
	_mesh.scale = Vector3(0.01, height, 0.01)


func _process(delta: float) -> void:
	_elapsed += delta
	var weight: float = clampf(_elapsed / DURATION_S, 0.0, 1.0)
	var reach: float = maxf(0.01, _radius * weight)
	_mesh.scale = Vector3(reach, _height, reach)
	_material.albedo_color.a = 0.35 * (1.0 - weight)
	if weight >= 1.0:
		queue_free()
