extends GutTest
## Greybox hub + sala 1 del Penal Altiplano contra las cotas de la ficha PUR-070 rev. 2.

const SANDBOX := preload("res://levels/domain_01/penal_altiplano_sandbox.tscn")
const Layout := preload("res://levels/domain_01/penal_altiplano_greybox.gd")
const GUN_HEIGHT := 0.5
const JUMP_TOP := 3.2
const LASER_RANGE := 60.0

var sandbox: Node3D
var greybox: PenalAltiplanoGreybox


func before_each() -> void:
	sandbox = add_child_autofree(SANDBOX.instantiate())
	greybox = sandbox.get_node("Greybox")
	await wait_physics_frames(3)


func test_floor_heights_and_slopes() -> void:
	assert_almost_eq(_ground_at(Vector3(12, 0, 6)), 0.0, 0.01, "Suelo del hub")
	assert_almost_eq(_ground_at(Vector3(3, 0, 3)), Layout.PODIUM_HEIGHT, 0.01, "Cima del podio")
	assert_almost_eq(_ground_at(Vector3(-14, 0, -60)), Layout.PLATFORM_HEIGHT, 0.01, "P1")
	assert_almost_eq(_ground_at(Vector3(0, 0, -27)), 0.0, 0.01, "Conexión 1")
	for gate: int in Layout.GATES:
		var axis: Vector3 = Layout.GATES[gate]
		_assert_slope(axis * 9.0, axis * 6.0, 18.43, "Rampa del podio %d" % gate)
	_assert_slope(Vector3(-14, 0, -49), Vector3(-14, 0, -53), 18.43, "Rampa RA")


func test_ceilings_and_portal_oculus() -> void:
	assert_almost_eq(_ceiling_above(Vector3(12, 1, 0)), Layout.HUB_CEILING, 0.01, "Techo del hub")
	assert_almost_eq(_ceiling_above(Vector3(0, 1, -27)), Layout.GATE_HEIGHT, 0.01, "Techo conexión")
	assert_almost_eq(_ceiling_above(Vector3(10, 1, -60)), Layout.ROOM_CEILING, 0.01, "Techo sala 1")
	var clearance: float = _ceiling_above(Vector3(-14, 2.5, -60)) - Layout.PLATFORM_HEIGHT
	assert_gt(clearance, Balance.get_f("movement.jump_apex_m") + 0.7, "Salto sobre P1")
	var ascent: float = Balance.get_f("portal.ascent_height_m")
	assert_eq(_ceiling_above(Vector3(0, 2, 0), ascent + 2.0), INF, "Óculo libre sobre el portal")


func test_spawns_clear_of_podium_ramps_with_margin() -> void:
	var spawns: Array[Node] = get_tree().get_nodes_in_group(&"spawn_points")
	assert_eq(spawns.size(), 8)
	var hull := BoxShape3D.new()
	# Casco 1 × 0.7 × 2.2 m más 0.2 m de margen por lado; elevado para no tocar el suelo.
	hull.size = Vector3(1.4, 0.7, 2.6)
	for spawn: Marker3D in spawns:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = hull
		query.collision_mask = 1
		query.transform = Transform3D(spawn.global_basis, spawn.global_position + Vector3.UP * 0.45)
		var hits: Array = greybox.get_world_3d().direct_space_state.intersect_shape(query)
		assert_eq(hits.size(), 0, "%s libre de rampas y podio" % spawn.name)
		var outward := Vector3(spawn.global_position.x, 0, spawn.global_position.z).normalized()
		assert_gt((-spawn.global_basis.z).dot(outward), 0.99, "%s mira hacia afuera" % spawn.name)


func test_reserves_hidden_from_hub_at_gun_and_jump_height() -> void:
	var reserves: Array[Node] = get_tree().get_nodes_in_group(&"design_reserve")
	assert_eq(reserves.size(), 6)
	var viewpoints: Array[Vector3] = []
	for ring: float in [8.0, 12.0, 16.0, 19.5]:
		for step: int in range(48):
			var angle: float = TAU * step / 48.0
			viewpoints.append(Vector3(sin(angle) * ring, 0, -cos(angle) * ring))
	for reserve: Marker3D in reserves:
		for height: float in [GUN_HEIGHT, JUMP_TOP]:
			var target: Vector3 = reserve.global_position + Vector3.UP * GUN_HEIGHT
			var seen: int = 0
			for point: Vector3 in viewpoints:
				if _clear(point + Vector3.UP * height, target):
					seen += 1
			assert_eq(seen, 0, "%s oculto desde el hub a %.1f m" % [reserve.name, height])


func test_longest_ground_line_within_laser_range() -> void:
	var longest: float = 0.0
	var worst: Array = []
	for origin: Vector3 in _walkable_grid(2.0):
		for step: int in range(180):
			var angle: float = TAU * step / 180.0
			var direction := Vector3(sin(angle), 0, cos(angle))
			var length: float = _ray_length(origin, direction, 120.0)
			if length > longest:
				longest = length
				worst = [origin, direction]
	gut.p("Línea libre más larga a %.1f m: %.1f m desde %s" % [GUN_HEIGHT, longest, worst])
	assert_lt(longest, LASER_RANGE, "Línea recta a ras de suelo ≤ alcance del láser")


func test_route_a_reaches_room_platform_and_portal() -> void:
	var events: Dictionary = await _run_route("a")
	assert_true(events.has("fin de ruta"), "Ruta A completa: %s" % events)
	assert_lt(events.get("entra sala 1", INF), 6.0, "Sala 1 en ≤ 6 s desde el spawn")
	assert_true(events.has("sobre P1"), "Ruta A sube a P1")
	assert_true(events.has("sobre podio"), "Ruta A vuelve al portal")


func test_route_b_loops_on_floor_and_returns() -> void:
	var events: Dictionary = await _run_route("b")
	assert_true(events.has("fin de ruta"), "Ruta B completa: %s" % events)
	assert_lt(events.get("entra sala 1", INF), 6.0, "Sala 1 en ≤ 6 s desde el spawn")
	assert_false(events.has("sobre P1"), "Ruta B es de suelo")
	assert_true(events.has("sobre podio"), "Ruta B vuelve al portal")


func _run_route(key: String) -> Dictionary:
	sandbox.start_route(key)
	for _second: int in range(25):
		await wait_physics_frames(60)
		if sandbox.route_finished:
			break
	gut.p("Ruta %s: %s" % [key, sandbox.route_events])
	return sandbox.route_events


func _walkable_grid(spacing: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var x: float = -Layout.CORRIDOR_END
	while x <= Layout.CORRIDOR_END:
		var z: float = Layout.ROOM_CENTER_Z - Layout.ROOM_HALF + 0.5
		while z <= Layout.HUB_RADIUS:
			var origin := Vector3(x, GUN_HEIGHT, z)
			if _is_open(origin):
				points.append(origin)
			z += spacing
		x += spacing
	return points


func _is_open(point: Vector3) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = 1
	var space := greybox.get_world_3d().direct_space_state
	if not space.intersect_point(query).is_empty():
		return false
	return _in_layout(point)


## Zonas transitables según la ficha. Las consultas de punto no detectan el interior de sólidos
## CSG cóncavos (muro del hub), así que se filtra por planta.
func _in_layout(point: Vector3) -> bool:
	var flat := Vector2(point.x, point.z)
	var inset: float = 0.2
	if flat.length() < Layout.HUB_RADIUS - inset:
		return true
	var half_gate: float = Layout.GATE_WIDTH / 2.0 - inset
	if absf(point.x) < half_gate and point.z <= 0.0:
		return point.z > -Layout.CORRIDOR_END
	if absf(point.z) < half_gate and point.x >= 0.0:
		return point.x < Layout.CORRIDOR_END
	var half: float = Layout.ROOM_HALF - inset
	return absf(point.x) < half and absf(point.z - Layout.ROOM_CENTER_Z) < half


func _ray_length(origin: Vector3, direction: Vector3, limit: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * limit, 1)
	var hit: Dictionary = greybox.get_world_3d().direct_space_state.intersect_ray(query)
	return origin.distance_to(hit.position) if not hit.is_empty() else limit


func _clear(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return greybox.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _assert_slope(low_point: Vector3, high_point: Vector3, degrees: float, label: String) -> void:
	var low: float = _ground_at(low_point)
	var high: float = _ground_at(high_point)
	var run: float = Vector2(low_point.x, low_point.z).distance_to(Vector2(high_point.x, high_point.z))
	assert_almost_eq(rad_to_deg(atan((high - low) / run)), degrees, 0.2, label)


func _ground_at(point: Vector3) -> float:
	var origin := Vector3(point.x, 4.5, point.z)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 10.0, 1)
	var hit: Dictionary = greybox.get_world_3d().direct_space_state.intersect_ray(query)
	assert_false(hit.is_empty(), "Debe existir suelo en %s" % point)
	return hit.get("position", Vector3(0, -100, 0)).y


func _ceiling_above(point: Vector3, limit: float = 20.0) -> float:
	var query := PhysicsRayQueryParameters3D.create(point, point + Vector3.UP * limit, 1)
	var hit: Dictionary = greybox.get_world_3d().direct_space_state.intersect_ray(query)
	return INF if hit.is_empty() else hit.position.y
