class_name HealthComponent
extends Node
## Salud y atribución; no modifica cuota, puntaje ni HUD.

var current: float = 0.0
var maximum: float = 0.0
var destroyed: bool = false
var in_safe_zone: bool = false
var spawn_shield_s: float = 0.0
var armored: bool = false
var _clock: float = 0.0
var _last_damage_at: float = -INF
var _last_attacker: WeakRef
@onready var runner: Runner = get_parent() as Runner


func reset(value: float) -> void:
	maximum = value
	current = value
	destroyed = false
	spawn_shield_s = 0.0
	armored = false
	_last_attacker = null
	_last_damage_at = -INF


func tick(delta: float) -> void:
	if not is_finite(delta) or delta < 0.0:
		return
	_clock += delta
	spawn_shield_s = maxf(0.0, spawn_shield_s - delta)


func apply(info: DamageInfo) -> float:
	if destroyed or not _valid_damage(info):
		return 0.0
	var source: Runner = info.source if is_instance_valid(info.source) else null
	var purge: bool = info.type == Enums.DamageType.PURGE
	var lethal: bool = purge or info.type == Enums.DamageType.BARRIER
	if source == runner and info.type not in [Enums.DamageType.RAM, Enums.DamageType.TOWER]:
		return 0.0
	if not purge and (in_safe_zone or (source != null and source.health.in_safe_zone)):
		return 0.0
	if not lethal and (spawn_shield_s > 0.0 or armored):
		return 0.0
	var amount: float = current if lethal else info.amount
	if info.type == Enums.DamageType.LASER:
		amount *= directional_multiplier(info.direction)
		if source != null:
			amount *= source.stats.laser_mult
	if not is_finite(amount) or amount <= 0.0:
		return 0.0
	if source != null and source != runner:
		_last_attacker = weakref(source)
		_last_damage_at = _clock
	var applied: float = minf(amount, current)
	current -= applied
	var died: bool = current <= 0.0
	destroyed = died
	var killer: Runner = credited_attacker() if died else null
	# Publicar estado final antes de invocar listeners que podrían volver a aplicar daño.
	EventBus.runner_damaged.emit(runner, info, current)
	if died:
		EventBus.runner_destroyed.emit(runner, killer, info.weapon_id)
	return applied


func directional_multiplier(direction: Vector3) -> float:
	# DamageInfo.direction va del atacante al blanco; invertir para localizar atacante.
	var incoming: Vector3 = -direction.slide(Vector3.UP).normalized()
	if incoming.is_zero_approx():
		return Balance.get_f("damage.directional.side_mult")
	var angle: float = rad_to_deg((-runner.global_basis.z).angle_to(incoming))
	if angle <= Balance.get_f("damage.directional.front_half_angle_deg"):
		return Balance.get_f("damage.directional.front_mult")
	if angle >= 180.0 - Balance.get_f("damage.directional.rear_half_angle_deg"):
		return Balance.get_f("damage.directional.rear_mult")
	return Balance.get_f("damage.directional.side_mult")


func credited_attacker() -> Runner:
	if _clock - _last_damage_at > Balance.get_f("attribution.last_damage_window_s"):
		return null
	return _last_attacker.get_ref() as Runner if _last_attacker != null else null


func _valid_damage(info: DamageInfo) -> bool:
	return info != null and is_finite(info.amount) and info.amount >= 0.0 and (
		info.type != Enums.DamageType.LASER or info.direction.is_finite()
	)
