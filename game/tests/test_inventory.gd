extends GutTest
## PUR-040: inventario de secundarias, pickups de arma y orbe de salud.

const RUNNER := preload("res://entities/runner/runner.tscn")
const PICKUP := preload("res://entities/pickups/pickup.tscn")

var runner: Runner


func before_each() -> void:
	runner = add_child_autofree(RUNNER.instantiate())
	runner.set_physics_process(false)
	await wait_physics_frames(1)


func test_three_repeatable_slots_and_full_rejects() -> void:
	var inventory: InventoryComponent = runner.inventory
	assert_eq(inventory.capacity(), 3)
	watch_signals(EventBus)
	for _index: int in range(3):
		assert_true(inventory.add(&"missile"), "Se pueden repetir")
	assert_true(inventory.is_full())
	assert_false(inventory.add(&"missile"), "Con los tres llenos no se recoge")
	assert_eq(inventory.slots.size(), 3)
	assert_signal_emit_count(EventBus, "inventory_changed", 3)


func test_cycle_wraps_and_take_keeps_selection_valid() -> void:
	var inventory: InventoryComponent = runner.inventory
	inventory.add(&"missile")
	inventory.add(&"shockwave")
	inventory.add(&"ram")
	assert_eq(inventory.selected_weapon(), &"missile")
	inventory.cycle(1)
	assert_eq(inventory.selected_weapon(), &"shockwave")
	inventory.cycle(-1)
	inventory.cycle(-1)
	assert_eq(inventory.selected_weapon(), &"ram", "Q desde el primero vuelve al último")
	assert_eq(inventory.take_selected(), &"ram")
	assert_eq(inventory.selected_weapon(), &"shockwave", "La selección sigue siendo válida")
	assert_eq(inventory.slots.size(), 2)


func test_input_frame_cycles_through_runner() -> void:
	runner.inventory.add(&"missile")
	runner.inventory.add(&"shockwave")
	runner.controller = null
	runner.input_frame.cycle_secondary = 1
	runner._physics_process(1.0 / 60.0)
	assert_eq(runner.inventory.selected_weapon(), &"shockwave")


func test_respawn_empties_slots() -> void:
	runner.inventory.add(&"missile")
	runner.reset_at(Vector3.ZERO)
	assert_eq(runner.inventory.slots.size(), 0, "Slots vacíos al reaparecer")


func test_weapon_pickup_collects_hides_and_respawns() -> void:
	var pickup: Pickup = add_child_autofree(PICKUP.instantiate())
	watch_signals(EventBus)
	assert_true(pickup.try_collect(runner))
	assert_eq(runner.inventory.slots, [&"missile"] as Array[StringName])
	assert_false(pickup.available)
	assert_signal_emitted_with_parameters(EventBus, "pickup_collected", [runner, &"missile"])
	var other: Runner = add_child_autofree(RUNNER.instantiate())
	other.set_physics_process(false)
	assert_false(pickup.try_collect(other), "No reaparece hasta 20 s")
	pickup.tick(Balance.get_f("inventory.weapon_pickup_respawn_s") - 0.1)
	assert_false(pickup.available)
	pickup.tick(0.2)
	assert_true(pickup.available, "Reaparece a los 20 s")


func test_full_inventory_leaves_pickup_in_place() -> void:
	for _index: int in range(3):
		runner.inventory.add(&"missile")
	var pickup: Pickup = add_child_autofree(PICKUP.instantiate())
	assert_false(pickup.try_collect(runner))
	assert_true(pickup.available, "El pickup sigue disponible para otro")


func test_health_orb_heals_capped_only_when_damaged() -> void:
	var orb: Pickup = PICKUP.instantiate()
	orb.kind = &"health_orb"
	add_child_autofree(orb)
	assert_false(orb.try_collect(runner), "Con integridad llena no se recoge")
	runner.health.current = runner.health.maximum - 10.0
	assert_true(orb.try_collect(runner))
	assert_eq(runner.health.current, runner.health.maximum, "Cura sin pasar del máximo")
	orb.tick(Balance.get_f("items.health_orb.respawn_s") + 0.1)
	assert_true(orb.available, "Reaparece a los 25 s")


func test_pickup_floats_and_spins() -> void:
	var pickup: Pickup = add_child_autofree(PICKUP.instantiate())
	var visual: Node3D = pickup.get_child(pickup.get_child_count() - 1)
	pickup.tick(0.4)
	var first := Vector2(visual.position.y, visual.rotation.y)
	pickup.tick(0.4)
	assert_ne(Vector2(visual.position.y, visual.rotation.y), first, "Flota y gira")
