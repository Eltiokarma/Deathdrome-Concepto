extends GutTest

const ARENA := preload("res://levels/_test/test_arena.tscn")
var arena: Node3D


func before_each() -> void:
	arena = add_child_autofree(ARENA.instantiate())
	await wait_physics_frames(3)


func test_world_dimensions_and_clearances() -> void:
	var floor_shape: BoxShape3D = arena.get_node("Floor/Collision").shape
	assert_eq(floor_shape.size, Vector3(60, 1, 60))
	var left: StaticBody3D = arena.get_node("CorridorLeft")
	var right: StaticBody3D = arena.get_node("CorridorRight")
	assert_eq(right.position.x - left.position.x - 1.0, 7.0)
	var ceiling: StaticBody3D = arena.get_node("Ceiling")
	assert_eq(ceiling.position.y - 0.25, 5.0)
	assert_eq(_ground_at(Vector3(-3, 10, -20)), 3.0)
	assert_almost_eq(_ground_at(Vector3(-9, 10, 10)), 1.2, 0.001)


func test_ramp_surfaces_are_collidable_and_have_expected_slope() -> void:
	for entry: Array in [["Ramp15", 15.0], ["Ramp25", 25.0]]:
		var ramp: CSGPolygon3D = arena.get_node(entry[0])
		var run: float = 3.0 / tan(deg_to_rad(entry[1]))
		# Extrusión local -Z se transforma hacia -X; longitud local +X hacia -Z.
		var start: Vector3 = ramp.position + Vector3(-3, 10, -run * 0.25)
		var end: Vector3 = ramp.position + Vector3(-3, 10, -run * 0.75)
		var low: float = _ground_at(start)
		var high: float = _ground_at(end)
		assert_almost_eq(low, 0.75, 0.02, entry[0] + " entrada")
		assert_almost_eq(high, 2.25, 0.02, entry[0] + " salida")
		assert_almost_eq(rad_to_deg(atan((high - low) / (run * 0.5))), entry[1], 0.1)


func _ground_at(origin: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 20, 1)
	var hit: Dictionary = arena.get_world_3d().direct_space_state.intersect_ray(query)
	assert_false(hit.is_empty(), "Debe existir superficie colisionable")
	return hit.get("position", Vector3(0, -100, 0)).y
