class_name RoundProgress
extends Node
## Cuotas por participante. Consume atribución de HealthComponent, no la recalcula.

var _participants: Dictionary = {}
var _kills: Dictionary = {}
var _counted_lives: Dictionary = {}
@onready var manager: RoundManager = get_parent() as RoundManager


func _ready() -> void:
	EventBus.round_intro_started.connect(_on_intro)
	EventBus.runner_destroyed.connect(_on_destroyed)


func register(runner: Runner) -> void:
	if not is_instance_valid(runner):
		return
	var id: int = runner.get_instance_id()
	_participants[id] = weakref(runner)
	if not _kills.has(id):
		_kills[id] = 0


func kills_for(runner: Runner) -> int:
	if not _registered(runner):
		return 0
	return _kills.get(runner.get_instance_id(), 0)


func has_quota(runner: Runner) -> bool:
	return _registered(runner) and kills_for(runner) >= manager.quota


func _registered(runner: Runner) -> bool:
	if not is_instance_valid(runner):
		return false
	var ref: WeakRef = _participants.get(runner.get_instance_id())
	return ref != null and ref.get_ref() == runner


func _on_intro(_domain: int, _round: int, _quota: int) -> void:
	if manager.state != RoundManager.State.INTRO:
		return
	_counted_lives.clear()
	for id: int in _participants.keys():
		var runner: Runner = _participants[id].get_ref() as Runner
		if runner == null:
			_participants.erase(id)
			_kills.erase(id)
			continue
		_kills[id] = 0
		EventBus.quota_progress_changed.emit(runner, 0, manager.quota)


func _on_destroyed(victim: Runner, killer: Runner, _weapon: StringName) -> void:
	if manager.state not in [RoundManager.State.PLAYING, RoundManager.State.PURGE]:
		return
	if not _registered(victim) or not victim.health.destroyed:
		return
	# Marcar incluso muertes sin atribución: no pueden recibir crédito retroactivo.
	var id: int = victim.get_instance_id()
	if _counted_lives.get(id, -1) == victim.health.life_id:
		return
	_counted_lives[id] = victim.health.life_id
	if killer == victim or not _registered(killer):
		return
	var killer_id: int = killer.get_instance_id()
	var count: int = kills_for(killer) + 1
	_kills[killer_id] = count
	EventBus.quota_progress_changed.emit(killer, count, manager.quota)
	if count == manager.quota:
		EventBus.quota_reached.emit(killer)


func is_participant(runner: Runner) -> bool:
	return _registered(runner)
