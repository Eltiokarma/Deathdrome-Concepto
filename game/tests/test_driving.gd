extends GutTest

const VEHICLE := preload("res://entities/runner/runner.tscn")
const ARENA := preload("res://levels/_test/test_arena.tscn")
var runner: Runner
var arena: Node3D


func before_each() -> void:
	arena = add_child_autofree(ARENA.instantiate())
	runner = VEHICLE.instantiate()
	runner.position = Vector3(-20, 0.05, 20)
	add_child_autofree(runner)
	runner.controller = null
	runner.set_physics_process(false)
	await _drive(InputFrame.new(), 12)


func test_acceleration_and_braking_respect_stats() -> void:
	var frame := InputFrame.new()
	frame.throttle = 1.0
	await _drive(frame, 115)
	assert_almost_eq(runner.velocity.length(), runner.stats.max_speed_mps, 1.5)
	frame.brake = 1.0
	await _drive(frame, 60)
	assert_lt(runner.velocity.length(), 0.1)


func test_jump_apex_and_cooldown() -> void:
	var origin: float = runner.position.y
	var frame := InputFrame.new()
	frame.jump = true
	await _drive(frame, 1)
	assert_gt(runner.motor.jump_cooldown, 1.1)
	frame.jump = false
	var peak: float = runner.position.y
	for i: int in 75:
		await _drive(frame, 1)
		peak = maxf(peak, runner.position.y)
	assert_almost_eq(peak - origin, 2.5, 0.1)
	assert_true(runner.is_on_floor())
	assert_almost_eq(runner.position.y, origin, 0.02)


func test_airborne_jump_does_not_double_jump() -> void:
	var frame := InputFrame.new()
	frame.jump = true
	await _drive(frame, 1)
	frame.jump = false
	await _drive(frame, 15)
	var before: float = runner.velocity.y
	frame.jump = true
	await _drive(frame, 1)
	assert_lt(runner.velocity.y, before)


func test_ramp_25_climbs_and_keeps_contact() -> void:
	runner.reset_at(Vector3(-2, 0.05, -8))
	await _drive(InputFrame.new(), 12)
	var frame := InputFrame.new()
	frame.throttle = 0.2
	var contact_frames: int = 0
	for i: int in 145:
		await _drive(frame, 1)
		if runner.is_on_floor():
			contact_frames += 1
	assert_gt(runner.position.y, 2.9)
	assert_gt(contact_frames, 130)


func test_slow_ledge_descent_does_not_fall_through_floor() -> void:
	runner.reset_at(Vector3(8, 3.05, -18), PI)
	await _drive(InputFrame.new(), 12)
	var frame := InputFrame.new()
	frame.throttle = 0.1
	var lowest: float = runner.position.y
	for i: int in 180:
		await _drive(frame, 1)
		lowest = minf(lowest, runner.position.y)
	assert_gt(lowest, -0.02)
	assert_true(runner.is_on_floor())
	assert_lt(runner.position.y, 0.05)


func test_wall_blocks_runner_at_high_speed() -> void:
	runner.reset_at(Vector3(-20, 0.05, -22))
	var frame := InputFrame.new()
	frame.throttle = 1.0
	await _drive(frame, 150)
	assert_gt(runner.position.z, -29.0)
	assert_true(runner.is_on_wall())


func test_runner_switch_applies_stats_and_resets_velocity() -> void:
	runner.setup(&"kuntur")
	assert_eq(runner.stats.max_speed_mps, 28.5)
	runner.velocity = Vector3(10, 0, 0)
	runner.setup(&"lloqlla")
	runner.reset_at(Vector3(-20, 0.05, 20))
	assert_eq(runner.stats.max_speed_mps, 21.0)
	assert_eq(runner.current_integrity, 130.0)
	assert_eq(runner.velocity, Vector3.ZERO)


func test_spring_arm_retracts_near_wall() -> void:
	runner.reset_at(Vector3(-20, 0.05, -28), PI)
	await _drive(InputFrame.new(), 30)
	var arm: SpringArm3D = runner.get_node("RunnerCamera/SpringArm3D")
	assert_lt(arm.get_hit_length(), arm.spring_length)
	var camera: Camera3D = arm.get_node("Camera3D")
	assert_gt(camera.global_position.z, -30.0)


func _drive(frame: InputFrame, ticks: int) -> void:
	for i: int in ticks:
		runner.last_input = frame.sanitized()
		runner.motor.step(runner, runner.last_input, 1.0 / 60.0)
		await wait_physics_frames(1)


func test_camera_modes_and_close_offset() -> void:
	var rig: RunnerCamera = runner.get_node("RunnerCamera")
	var camera: Camera3D = rig.camera
	assert_eq(camera.fov, 60.0)
	assert_almost_eq(camera.global_position.y - runner.global_position.y, 1.4, 0.02)
	assert_almost_eq(rig.arm.spring_length, 3.6, 0.00001)
	rig.mode = 1
	rig._apply_mode()
	assert_eq(rig.arm.spring_length, 7.0)
	rig.mode = 2
	rig._apply_mode()
	assert_eq(rig.arm.spring_length, 0.0)
	assert_false(runner.model.visible)
	rig.mode = 0
	rig._apply_mode()
	assert_true(runner.model.visible)
