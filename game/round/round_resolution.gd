class_name RoundResolution
extends Node
## Final opcional de ronda: todos escaparon o quedaron sin reaparicion durante la Purga.
## No usa el grupo runners: el portal retira de ese grupo a quienes estan ascendiendo.

@export var manager_path: NodePath
@export var progress_path: NodePath
var _escaped: Dictionary = {}
var _purging: bool = false
var _generation: int = 0
var _evaluation_queued: bool = false
@onready var manager: RoundManager = get_node(manager_path)
@onready var progress: RoundProgress = get_node(progress_path)


func _ready() -> void:
	EventBus.round_state_changed.connect(_on_state)
	EventBus.runner_destroyed.connect(_on_destroyed)
	EventBus.runner_escaped.connect(_on_escaped)
	EventBus.purge_closed.connect(_queue_evaluation)


func has_escaped(runner: Runner) -> bool:
	return is_instance_valid(runner) and _escaped.has(runner.get_instance_id())


func counts() -> Dictionary:
	var result: Dictionary = {"participants": 0, "escaped": 0, "destroyed": 0, "pending": 0}
	for runner: Runner in progress.participants():
		result.participants += 1
		if has_escaped(runner):
			result.escaped += 1
		elif _purging and runner.health.destroyed:
			result.destroyed += 1
		else:
			result.pending += 1
	return result


func _on_state(state: int) -> void:
	if manager.state != state:
		return
	if state == RoundManager.State.INTRO:
		_generation += 1
		_evaluation_queued = false
		_escaped.clear()
		_purging = false
	elif state == RoundManager.State.PURGE:
		_purging = true
		_queue_evaluation()
	elif state == RoundManager.State.PLAYING:
		_queue_evaluation()


func _on_destroyed(victim: Runner, _killer: Runner, _weapon: StringName) -> void:
	if progress.is_participant(victim) and victim.health.destroyed:
		_queue_evaluation()


func _on_escaped(runner: Runner, time_left: float) -> void:
	if not _playing() or not progress.has_quota(runner) or runner.health.destroyed:
		return
	if not is_finite(time_left) or time_left < 0.0 or time_left > Balance.get_f("round.duration_s"):
		return
	_escaped[runner.get_instance_id()] = true
	_queue_evaluation()


func _playing() -> bool:
	return manager.state in [RoundManager.State.PLAYING, RoundManager.State.PURGE]


func _queue_evaluation() -> void:
	if _evaluation_queued or not _playing():
		return
	_evaluation_queued = true
	# Espera a que todas las suscripciones reciban muerte/escape y calculen los puntos.
	_evaluate.call_deferred(_generation)


func _evaluate(generation: int) -> void:
	if generation != _generation:
		return
	_evaluation_queued = false
	if not _playing():
		return
	var result: Dictionary = counts()
	if result.participants == 0 or result.pending > 0:
		return
	result["reason"] = "all_resolved"
	manager.finish(result)
