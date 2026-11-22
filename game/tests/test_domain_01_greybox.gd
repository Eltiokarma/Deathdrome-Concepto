extends GutTest
## Greybox hub + sala 1 del Penal Altiplano contra la ficha PUR-070 rev. 4 (escala oficial).

const SANDBOX := preload("res://levels/domain_01/penal_altiplano_sandbox.tscn")
const Layout := preload("res://levels/domain_01/penal_altiplano_greybox.gd")
const GUN_HEIGHT := 0.5
const JUMP_TOP := 3.2
## Métrica de docs/04: ninguna recta libre supera 1.5 veces el alcance del láser.
const LINE_LIMIT_FACTOR := 1.5
const ROOM_REACH_S := 10.0
const ROUTE_LIMIT_S := 80

var sandbox: Node3D
var greybox: PenalAltiplanoGreybox


func before_each() -> void:
	sandbox = add_child_autofree(SANDBOX.instantiate())
	greybox = sandbox.get_node("Greybox")
	await wait_physics_frames(3)


func test_official_scale_dimensions() -> void:
	assert_true(greybox.is_large(), "La escala oficial construye la sala grande")
	assert_almost_eq(greybox.hub_radius, 60.0, 0.001, "Hub Ø120 m")
	assert_almost_eq(greybox.corridor_end - greybox.hub_radius, 84.0, 0.001, "Conexión de 84 m")
	assert_almost_eq(greybox.room_half * 2.0, 216.0, 0.001, "Sala de 216 m")


func test_floor_heights_and_slopes() -> void:
	assert_almost_eq(_ground_at(Vector3(30, 0, 20)), 0.0, 0.01, "Suelo del hub")
	# La barrera del portal (sin cuota) cubre la cima del podio; se aparta para medir el podio.
	sandbox.get_node("Portal/Gate/Shape").disabled = true
	await wait_physics_frames(2)
	assert_almost_eq(_ground_at(Vector3(3, 0, 3)), Layout.PODIUM_HEIGHT, 0.01, "Cima del podio")
	assert_almost_eq(_ground_at(Vector3(0, 0, -100)), 0.0, 0.01, "Conexión 1")
	var ledge: float = Layout.LARGE_LEDGE_HEIGHT
	assert_almost_eq(_ground_room(-102, 120), ledge, 0.01, "Pasarela oeste")
	assert_almost_eq(_ground_room(0, 210), ledge, 0.01, "Pasarela norte")
	assert_almost_eq(_ground_room(0, 114), ledge, 0.01, "Plataforma central")
	assert_almost_eq(_ground_room(0, 40), 0.0, 0.01, "Calle del campo de pilares")
	for gate: int in Layout.GATES:
		var axis: Vector3 = Layout.GATES[gate]
		_assert_slope(axis * 9.0, axis * 6.0, 18.43, "Rampa del podio %d" % gate)
	_assert_slope(_room3(-102, 17), _room3(-102, 22), 18.43, "Rampa a pasarela oeste")
	_assert_slope(_room3(0, 87), _room3(0, 92), 18.43, "Rampa sur de la plataforma")


func test_three_height_levels_per_room_with_continuous_ramps() -> void:
	for gate: int in Layout.GATES:
		var layout: Dictionary = Layout.room_layout(gate)
		assert_gt(layout.ledges.size(), 0, "Sala %d: nivel +3" % gate)
		assert_gt(layout.get("decks", []).size(), 0, "Sala %d: nivel +6" % gate)
		for deck: Array in layout.decks:
			var center: Vector3 = _room3((deck[0] + deck[1]) / 2.0, (deck[2] + deck[3]) / 2.0,
					gate)
			assert_almost_eq(_ground_at(center, 8.0), Layout.LARGE_DECK_HEIGHT, 0.01,
					"Sala %d: mirador a +6 m" % gate)
		for ramp: Array in layout.ramps:
			var base: float = ramp[4] if ramp.size() > 4 else 0.0
			var direction: Vector2 = ramp[2]
			var low: Vector2 = Vector2(ramp[0], ramp[1]) + direction * 1.0
			var high: Vector2 = Vector2(ramp[0], ramp[1]) + direction * (Layout.LARGE_RAMP_RUN - 1.0)
			var rise: float = Layout.LARGE_LEDGE_HEIGHT
			assert_almost_eq(_ground_at(_room3(low.x, low.y, gate), 8.0),
					base + rise / Layout.LARGE_RAMP_RUN, 0.05, "Sala %d: pie de rampa" % gate)
			assert_almost_eq(_ground_at(_room3(high.x, high.y, gate), 8.0),
					base + rise * (1.0 - 1.0 / Layout.LARGE_RAMP_RUN), 0.05,
					"Sala %d: cima de rampa" % gate)


func test_bridges_tunnels_and_kickers_geometry() -> void:
	var slab_count: int = 0
	var kicker_count: int = 0
	for gate: int in Layout.GATES:
		var layout: Dictionary = Layout.room_layout(gate)
		for slab: Array in layout.get("slabs", []):
			slab_count += 1
			var center: Vector3 = _room3((slab[0] + slab[1]) / 2.0, (slab[2] + slab[3]) / 2.0,
					gate)
			var top: float = slab[4]
			var under: float = _ceiling_above(center + Vector3.UP * 0.5) if _ground_at(
					center, top - Layout.SLAB_THICKNESS - 0.1) < 0.1 else INF
			assert_almost_eq(_ground_at(center, top + 2.0), top, 0.01, "Sala %d: losa" % gate)
			if is_finite(under):
				assert_almost_eq(under, top - Layout.SLAB_THICKNESS, 0.01,
						"Sala %d: paso bajo la losa" % gate)
				assert_gt(under, 1.5, "Sala %d: cabe un Runner bajo la losa" % gate)
		for kicker: Array in layout.get("kickers", []):
			kicker_count += 1
			var direction: Vector2 = kicker[2]
			var low: Vector2 = Vector2(kicker[0], kicker[1]) + direction * 0.5
			var high: Vector2 = Vector2(kicker[0], kicker[1]) + direction * (Layout.KICKER_RUN - 0.5)
			var rise: float = (_ground_at(_room3(high.x, high.y, gate))
					- _ground_at(_room3(low.x, low.y, gate)))
			assert_almost_eq(rad_to_deg(atan(rise / (Layout.KICKER_RUN - 1.0))),
					rad_to_deg(atan(Layout.KICKER_RISE / Layout.KICKER_RUN)), 0.3,
					"Sala %d: rampa de salto" % gate)
	assert_gte(slab_count, 5, "Puentes y techos de túnel")
	assert_gte(kicker_count, 6, "Rampas de salto")


func test_bridge_tunnel_and_kicker_routes() -> void:
	var checks := {
		"1p": "cruza un puente", "2s": "aterriza en altura", "3t": "pasa bajo puente o túnel",
		"4s": "aterriza en altura",
	}
	for key: String in checks:
		var events: Dictionary = await _run_route(key)
		assert_true(events.has("fin de ruta"), "Ruta %s completa: %s" % [key, events])
		assert_true(events.has(checks[key]), "Ruta %s: %s" % [key, checks[key]])
	var jump: Dictionary = await _run_route("2s")
	assert_true(jump.has("cruza un puente") and jump.has("pasa bajo puente o túnel"),
			"La sala 2 se cruza por encima y por debajo del puente")


func test_ceilings_and_portal_oculus() -> void:
	assert_almost_eq(_ceiling_above(Vector3(30, 1, 20)), Layout.HUB_CEILING, 0.01, "Techo del hub")
	assert_almost_eq(_ceiling_above(Vector3(0, 1, -100)), Layout.GATE_HEIGHT, 0.01, "Techo conexión")
	var room_floor := _room3(56, 40) + Vector3.UP
	assert_almost_eq(_ceiling_above(room_floor), Layout.LARGE_ROOM_CEILING, 0.01, "Techo sala 1")
	var over_ledge: Vector3 = _room3(-102, 120) + Vector3.UP * (Layout.LARGE_LEDGE_HEIGHT + 0.5)
	var clearance: float = _ceiling_above(over_ledge) - Layout.LARGE_LEDGE_HEIGHT
	assert_gt(clearance, Balance.get_f("movement.jump_apex_m") + 0.7, "Salto sobre pasarela")
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
	var expected: int = 0
	for gate: int in Layout.GATES:
		expected += Layout.room_layout(gate).reserves.size()
	assert_eq(reserves.size(), expected)
	var viewpoints: Array[Vector3] = []
	for ring: float in [8.0, 12.0, 0.5, 0.8, 0.99]:
		var radius: float = ring if ring > 1.0 else greybox.hub_radius * ring
		for step: int in range(48):
			var angle: float = TAU * step / 48.0
			viewpoints.append(Vector3(sin(angle) * radius, 0, -cos(angle) * radius))
	for reserve: Node3D in reserves:
		for height: float in [GUN_HEIGHT, JUMP_TOP]:
			var target: Vector3 = reserve.global_position + Vector3.UP * GUN_HEIGHT
			var seen: int = 0
			for point: Vector3 in viewpoints:
				if _clear(point + Vector3.UP * height, target):
					seen += 1
			assert_eq(seen, 0, "%s oculto desde el hub a %.1f m" % [reserve.name, height])


func test_longest_ground_line_within_metric() -> void:
	var limit: float = Balance.get_f("weapons.laser.range_m") * LINE_LIMIT_FACTOR
	var longest: float = 0.0
	var worst: Array = []
	for origin: Vector3 in _walkable_grid(4.0):
		for step: int in range(180):
			var angle: float = TAU * step / 180.0
			var direction := Vector3(sin(angle), 0, cos(angle))
			var length: float = _ray_length(origin, direction, limit * 2.0)
			if length > longest:
				longest = length
				worst = [origin, direction]
	gut.p("Línea libre más larga a %.1f m: %.1f m desde %s" % [GUN_HEIGHT, longest, worst])
	assert_lt(longest, limit, "Recta a ras de suelo ≤ 1.5 × alcance del láser")


func test_route_a_climbs_ledges_and_returns_to_portal() -> void:
	var events: Dictionary = await _run_route("a")
	assert_true(events.has("fin de ruta"), "Ruta A completa: %s" % events)
	assert_lt(events.get("entra sala 1", INF), ROOM_REACH_S, "Sala 1 alcanzable desde el spawn")
	assert_true(events.has("sobre pasarela/plataforma"), "Ruta A usa la altura")
	assert_true(events.has("sobre mirador"), "Ruta A cruza el mirador de +6 m")
	assert_true(events.has("llega al portal"), "Ruta A vuelve al portal")


func test_route_b_loops_on_floor_and_returns() -> void:
	var events: Dictionary = await _run_route("b")
	assert_true(events.has("fin de ruta"), "Ruta B completa: %s" % events)
	assert_lt(events.get("entra sala 1", INF), ROOM_REACH_S, "Sala 1 alcanzable desde el spawn")
	assert_false(events.has("sobre pasarela/plataforma"), "Ruta B es de suelo")
	assert_true(events.has("llega al portal"), "Ruta B vuelve al portal")


func test_rooms_2_to_4_loops_climb_and_return() -> void:
	for gate: int in [2, 3, 4]:
		var events: Dictionary = await _run_route(str(gate))
		assert_true(events.has("fin de ruta"), "Ruta de sala %d completa: %s" % [gate, events])
		assert_lt(events.get("entra sala %d" % gate, INF), ROOM_REACH_S, "Sala %d alcanzable" % gate)
		assert_true(events.has("sobre pasarela/plataforma"), "Sala %d tiene juego vertical" % gate)
		assert_true(events.has("llega al portal"), "Sala %d vuelve al portal" % gate)


func test_every_room_has_minimum_content() -> void:
	# docs/04 §2 (escalado): torres, secundarias, salud, altura y coberturas en cada sala.
	for gate: int in Layout.GATES:
		var layout: Dictionary = Layout.room_layout(gate)
		var counts := {"T": 0, "M": 0, "H": 0}
		for id: String in layout.reserves:
			counts[id.left(1)] += 1
		assert_between(counts.T, 4, 6, "Sala %d: torres" % gate)
		assert_gte(counts.M, 5, "Sala %d: secundarias" % gate)
		assert_gte(counts.H, 2, "Sala %d: salud" % gate)
		assert_gt(layout.ledges.size(), 0, "Sala %d: zona de altura" % gate)
		assert_gte(layout.pillars.size(), 12, "Sala %d: coberturas" % gate)


func _run_route(key: String) -> Dictionary:
	sandbox.start_route(key)
	for _second: int in range(ROUTE_LIMIT_S):
		await wait_physics_frames(60)
		if sandbox.route_finished:
			break
	gut.p("Ruta %s: %s" % [key, sandbox.route_events])
	return sandbox.route_events


func _room3(u: float, d: float, gate: int = 1) -> Vector3:
	var point: Vector2 = greybox.room_point(u, d, gate)
	return Vector3(point.x, 0, point.y)


func _ground_room(u: float, d: float) -> float:
	return _ground_at(_room3(u, d))


func _walkable_grid(spacing: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var reach: float = greybox.corridor_end + 2.0 * greybox.room_half
	var x: float = -reach
	while x <= reach:
		var z: float = -reach
		while z <= reach:
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
	# Excluye puntos bajo rampas o pasarelas: el primer suelo desde arriba debe ser el piso.
	var probe := Vector3(point.x, 4.5, point.z)
	var down := PhysicsRayQueryParameters3D.create(probe, probe + Vector3.DOWN * 6.0, 1)
	var hit: Dictionary = space.intersect_ray(down)
	if hit.is_empty() or hit.position.y > 0.3:
		return false
	return _in_layout(point)


## Zonas transitables según la ficha. Las consultas de punto no detectan el interior de sólidos
## CSG cóncavos (muro del hub), así que se filtra por planta.
func _in_layout(point: Vector3) -> bool:
	var flat := Vector2(point.x, point.z)
	var inset: float = 0.2
	if flat.length() < greybox.hub_radius - inset:
		return true
	for gate: int in Layout.GATES:
		var axis: Vector3 = Layout.GATES[gate]
		var along: float = point.dot(axis)
		var lateral: float = absf(point.dot(axis.cross(Vector3.UP)))
		if along > greybox.hub_radius and along < greybox.corridor_end:
			if lateral < Layout.GATE_WIDTH / 2.0 - inset:
				return true
		var room_end: float = greybox.corridor_end + 2.0 * greybox.room_half
		if along > greybox.corridor_end + inset and along < room_end - inset:
			if lateral < greybox.room_half - inset:
				return true
	return false


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


func _ground_at(point: Vector3, from_height: float = 4.5) -> float:
	var origin := Vector3(point.x, from_height, point.z)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 10.0, 1)
	var hit: Dictionary = greybox.get_world_3d().direct_space_state.intersect_ray(query)
	assert_false(hit.is_empty(), "Debe existir suelo en %s" % point)
	return hit.get("position", Vector3(0, -100, 0)).y


func _ceiling_above(point: Vector3, limit: float = 20.0) -> float:
	var query := PhysicsRayQueryParameters3D.create(point, point + Vector3.UP * limit, 1)
	var hit: Dictionary = greybox.get_world_3d().direct_space_state.intersect_ray(query)
	return INF if hit.is_empty() else hit.position.y
