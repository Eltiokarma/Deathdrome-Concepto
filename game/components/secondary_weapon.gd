class_name SecondaryWeapon
extends Node
## Consume una carga al disparar. La selección y las órdenes llegan por InputFrame.

var cooldown_left: float = 0.0
@onready var runner: Runner = get_parent() as Runner
@onready var lock: MissileLock = runner.get_node("MissileLock")


func reset() -> void:
	cooldown_left = 0.0
	lock.reset()


func tick(delta: float, pressed: bool) -> void:
	if get_tree().paused or not is_finite(delta) or delta < 0.0:
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	var permitted: bool = runner.is_physics_processing() and not runner.health.destroyed and (
			not runner.health.in_safe_zone and runner.is_in_group("runners"))
	var selected: StringName = runner.inventory.selected_weapon()
	lock.tick(delta, permitted and selected == &"missile")
	if not pressed or not permitted or cooldown_left > 0.0:
		return
	if selected not in [&"missile", &"shockwave"]:
		return
	# Validar antes de consumir: una carga futura/desconocida nunca desaparece por pulsar K.
	runner.inventory.take_selected()
	if Balance.get_b("respawn.spawn_shield_breaks_on_fire"):
		runner.health.spawn_shield_s = 0.0
	runner.health.cloaked = false
	cooldown_left = Balance.get_f("inventory.secondary_cooldown_s")
	if selected == &"missile":
		var projectile := MissileProjectile.new()
		runner.get_parent().add_child(projectile)
		projectile.global_position = runner.laser.global_position
		projectile.setup(runner, -runner.global_basis.z, lock.locked_target())
	else:
		BlastDamage.apply(runner, runner, &"shockwave")
	lock.reset()
	EventBus.secondary_fired.emit(runner, selected)
