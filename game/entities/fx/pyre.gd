class_name Pyre
extends Node3D
## PUR-023: explosión breve y pira de fuego sobre los restos durante `death.pyre_s`.
## Greybox: billboard animado por código (parpadeo de tamaño y color) y luz; el arte final
## (sprite animado) llega con PUR-072/073.

const EXPLOSION_S := 0.4
var remaining: float = 0.0
var _age: float = 0.0
var _flame := MeshInstance3D.new()
var _flash := MeshInstance3D.new()
var _light := OmniLight3D.new()
var _material := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("pyres")
	remaining = Balance.get_f("death.pyre_s")
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_material.albedo_color = Color(1.0, 0.5, 0.1, 0.85)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.6, 2.2)
	quad.material = _material
	_flame.mesh = quad
	_flame.position.y = 1.1
	add_child(_flame)
	var sphere := SphereMesh.new()
	var flash_material := StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_material.albedo_color = Color(1.0, 0.9, 0.5, 0.7)
	sphere.material = flash_material
	_flash.mesh = sphere
	_flash.position.y = 0.6
	add_child(_flash)
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.omni_range = 8.0
	_light.position.y = 1.5
	add_child(_light)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	_age += delta
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var explosion: float = clampf(_age / EXPLOSION_S, 0.0, 1.0)
	_flash.visible = explosion < 1.0
	_flash.scale = Vector3.ONE * (0.5 + explosion * 4.0)
	var flicker: float = 0.85 + 0.15 * sin(_age * 23.0) * sin(_age * 7.0)
	_flame.scale = Vector3(flicker, 0.9 + 0.2 * sin(_age * 17.0), 1.0)
	var fade: float = clampf(remaining, 0.0, 1.0)
	_material.albedo_color = Color(1.0, 0.35 + 0.25 * flicker, 0.1, 0.85 * fade)
	_light.light_energy = 2.5 * flicker * fade
