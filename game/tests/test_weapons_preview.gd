extends GutTest
## La demostración usa InputFrame y las armas reales; sus resultados también se verifican.

const SCENE := preload("res://levels/_test/weapons_sandbox.tscn")


func test_preview_shows_missile_chain_and_jump_counterplay() -> void:
	var scene: Node3D = add_child_autofree(SCENE.instantiate())
	scene.start_preview()
	await wait_physics_frames(17 * 60)
	var events: Dictionary = scene.preview_events
	gut.p("Weapons demo: %s" % events)
	assert_eq(events.get("missile", 0), 1)
	assert_eq(events.get("shockwave", 0), 2)
	assert_eq(events.get("towers", 0), 4, "Dos torres por onda y luego dos por láser")
	assert_almost_eq(events.get("missile_damage", 0.0), Balance.get_f("weapons.missile.damage"), 0.01)
	assert_gt(events.get("ground_damage", 0.0), 0.0)
	assert_eq(events.get("jumper_damage", -1.0), 0.0, "El salto evita la onda")
