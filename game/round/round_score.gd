class_name RoundScore
extends Node
## Puntaje de la sesión; la campaña futura debe conservar o persistir este estado.

var _totals: Dictionary = {}
var _deaths: Dictionary = {}
var _mercy: Dictionary = {}
var _escaped: Dictionary = {}
var _first_blood: bool = false
@onready var progress: RoundProgress = get_parent() as RoundProgress
@onready var manager: RoundManager = progress.get_parent() as RoundManager


func _ready() -> void:
	EventBus.round_intro_started.connect(_on_intro)
	EventBus.runner_destroyed.connect(_on_destroyed)
	EventBus.mercy_kill.connect(_on_mercy)
	EventBus.runner_escaped.connect(_on_escaped)


func points_for(runner: Runner) -> int:
	return _totals.get(runner.get_instance_id(), 0) if progress.is_participant(runner) else 0


func _playing() -> bool:
	return manager.state in [RoundManager.State.PLAYING, RoundManager.State.PURGE]


func _on_intro(_domain: int, _round: int, _quota: int) -> void:
	if manager.state != RoundManager.State.INTRO:
		return
	_deaths.clear()
	_mercy.clear()
	_escaped.clear()
	_first_blood = false


func _on_destroyed(victim: Runner, killer: Runner, weapon: StringName) -> void:
	if not _playing() or not progress.is_participant(victim) or not victim.health.destroyed:
		return
	var id: int = victim.get_instance_id()
	if _deaths.get(id, -1) == victim.health.life_id:
		return
	_deaths[id] = victim.health.life_id
	if killer == null or killer == victim:
		_award(victim, Balance.get_i("score.suicide"), &"unattributed_death")
		return
	if not progress.is_participant(killer):
		return
	var points: int = Balance.get_i("score.kill")
	if not _first_blood:
		_first_blood = true
		points += Balance.get_i("score.first_blood")
	if weapon == &"barrier":
		points += Balance.get_i("score.barrier_kill_bonus")
	elif weapon == &"tower":
		points += Balance.get_i("score.tower_kill_bonus")
	_award(killer, points, &"kill")


func _on_mercy(killer: Runner, victim: Runner) -> void:
	if not _playing() or killer == victim or not progress.is_participant(killer):
		return
	if not progress.is_participant(victim) or not victim.health.destroyed:
		return
	var id: int = victim.get_instance_id()
	if _mercy.get(id, -1) == victim.health.life_id:
		return
	_mercy[id] = victim.health.life_id
	_award(killer, Balance.get_i("score.mercy_kill"), &"mercy_kill")


func _on_escaped(runner: Runner, time_left: float) -> void:
	if not _playing() or not progress.has_quota(runner) or runner.health.destroyed:
		return
	if not is_finite(time_left) or time_left < 0.0 or time_left > Balance.get_f("round.duration_s"):
		return
	var id: int = runner.get_instance_id()
	if _escaped.has(id):
		return
	_escaped[id] = true
	var points: int = Balance.get_i("score.round_clear") + floori(time_left) * Balance.get_i(
		"score.time_left_per_s")
	# La fase al completar el ascenso puede cambiar: importa el reloj de entrada.
	if time_left == 0.0:
		points += Balance.get_i("score.purge_escape_bonus")
	_award(runner, points, &"escape")


func _award(runner: Runner, points: int, reason: StringName) -> void:
	_totals[runner.get_instance_id()] = points_for(runner) + points
	EventBus.score_changed.emit(runner, points, reason)
