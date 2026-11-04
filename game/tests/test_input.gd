extends GutTest


func test_input_frame_sanitizes_untrusted_control_values() -> void:
	var frame := InputFrame.new()
	frame.throttle = 4.0
	frame.brake = NAN
	frame.steering = -10.0
	frame.cycle_secondary = 99
	var clean: InputFrame = frame.sanitized()
	assert_eq(clean.throttle, 1.0)
	assert_eq(clean.brake, 0.0)
	assert_eq(clean.steering, -1.0)
	assert_eq(clean.cycle_secondary, 1)
	assert_eq(frame.throttle, 4.0)


func test_all_documented_actions_are_mapped() -> void:
	for action: String in ["accelerate", "brake", "steer_left", "steer_right", "jump",
		"laser", "secondary", "barrier", "previous_secondary", "next_secondary",
		"cycle_camera", "look_back", "radar", "pause"]:
		assert_true(InputMap.has_action(action), action)
		assert_gte(InputMap.action_get_events(action).size(), 2, action)


func test_keyboard_release_preserves_held_gamepad_trigger() -> void:
	var player: PlayerInput = add_child_autofree(PlayerInput.new())
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	Input.parse_input_event(trigger)
	await wait_process_frames(1)
	assert_almost_eq(player.sample().throttle, 1.0, 0.001)
	key.pressed = false
	Input.parse_input_event(key)
	await wait_process_frames(1)
	assert_almost_eq(player.sample().throttle, 1.0, 0.001)
	trigger.axis_value = 0.0
	Input.parse_input_event(trigger)
	await wait_process_frames(1)
	assert_eq(player.sample().throttle, 0.0)


func test_event_bus_has_typed_gameplay_contracts() -> void:
	assert_true(EventBus.has_signal("runner_damaged"))
	assert_true(EventBus.has_signal("round_ended"))
	assert_true(EventBus.has_signal("runner_escaped"))
	var info := DamageInfo.new()
	assert_eq(info.amount, 0.0)
	assert_null(info.source)
	assert_eq(Enums.AreaId.HUB, 0)


func test_pause_can_be_toggled_without_losing_resume() -> void:
	var scene: PackedScene = load("res://levels/_test/driving_sandbox.tscn")
	var sandbox: Node3D = add_child_autofree(scene.instantiate())
	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	sandbox._unhandled_input(event)
	var paused: bool = get_tree().paused
	sandbox._unhandled_input(event)
	assert_true(paused)
	assert_false(get_tree().paused)
