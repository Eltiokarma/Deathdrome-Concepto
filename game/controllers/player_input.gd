class_name PlayerInput
extends Node
## InputMap combina teclado/mando sin cambiar el contrato del Runner.


func sample() -> InputFrame:
	var frame := InputFrame.new()
	frame.throttle = Input.get_action_strength("accelerate")
	frame.brake = Input.get_action_strength("brake")
	frame.steering = Input.get_axis("steer_left", "steer_right")
	frame.jump = Input.is_action_just_pressed("jump")
	frame.laser = Input.is_action_pressed("laser")
	frame.secondary = Input.is_action_just_pressed("secondary")
	frame.barrier = Input.is_action_pressed("barrier")
	frame.cycle_secondary = int(Input.is_action_just_pressed("next_secondary")) - int(
		Input.is_action_just_pressed("previous_secondary")
	)
	frame.cycle_camera = Input.is_action_just_pressed("cycle_camera")
	frame.look_back = Input.is_action_pressed("look_back")
	frame.radar = Input.is_action_pressed("radar")
	frame.pause = Input.is_action_just_pressed("pause")
	return frame
