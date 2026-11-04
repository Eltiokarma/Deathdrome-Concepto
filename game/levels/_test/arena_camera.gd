extends Camera3D
## Cámara de inspección del greybox; no es la cámara de Runner de PUR-014.

var _distance: float = 85.0
var _angle: float = 0.73


func _ready() -> void:
	_update_transform()


func _process(delta: float) -> void:
	_angle += Input.get_axis("ui_left", "ui_right") * delta * 0.6
	_update_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(25.0, _distance - 4.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(110.0, _distance + 4.0)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		_distance = 85.0
		_angle = 0.73


func _update_transform() -> void:
	position = Vector3(sin(_angle), 0.75, cos(_angle)).normalized() * _distance
	look_at(Vector3.ZERO)
