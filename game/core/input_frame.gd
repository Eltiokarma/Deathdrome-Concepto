class_name InputFrame
extends RefCounted
## Único contrato de control consumido por Runner; reutilizable por bots y replay.

var throttle: float = 0.0
var brake: float = 0.0
var steering: float = 0.0
var jump: bool = false
var laser: bool = false
var secondary: bool = false
var barrier: bool = false
var cycle_secondary: int = 0
var cycle_camera: bool = false
var look_back: bool = false
var radar: bool = false
var pause: bool = false


func sanitized() -> InputFrame:
	var result := InputFrame.new()
	result.throttle = clampf(throttle, 0.0, 1.0) if is_finite(throttle) else 0.0
	result.brake = clampf(brake, 0.0, 1.0) if is_finite(brake) else 0.0
	result.steering = clampf(steering, -1.0, 1.0) if is_finite(steering) else 0.0
	result.jump = jump
	result.laser = laser
	result.secondary = secondary
	result.barrier = barrier
	result.cycle_secondary = clampi(cycle_secondary, -1, 1)
	result.cycle_camera = cycle_camera
	result.look_back = look_back
	result.radar = radar
	result.pause = pause
	return result
