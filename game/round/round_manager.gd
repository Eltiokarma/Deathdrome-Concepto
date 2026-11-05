class_name RoundManager
extends Node
## Ciclo de ronda. El nivel decide cuándo terminar; no simula portal ni muros de Purga.

enum State { LOADING, INTRO, COUNTDOWN, PLAYING, PURGE, RESULTS }

var state: State = State.LOADING
var domain_id: int = 1
var round_index: int = 1
var quota: int = 2
var seconds_left: float = 0.0
var phase_left: float = 0.0


func _physics_process(delta: float) -> void:
	tick(delta)


func quota_for(domain: int, index: int) -> int:
	return mini(Balance.get_i("round.quota_base") + floori((domain - 1) / 2.0)
		+ index - 1, Balance.get_i("round.quota_max"))


func begin(domain: int, index: int) -> bool:
	if state not in [State.LOADING, State.RESULTS] or domain < 1 or domain > 8:
		return false
	if index < 1 or index > 3:
		return false
	domain_id = domain
	round_index = index
	quota = quota_for(domain, index)
	seconds_left = Balance.get_f("round.duration_s")
	phase_left = Balance.get_f("round.intro_s")
	_set_state(State.INTRO)
	EventBus.round_intro_started.emit(domain_id, round_index, quota)
	return true


func tick(delta: float) -> void:
	if get_tree().paused or not is_finite(delta) or delta <= 0.0:
		return
	var remaining: float = delta
	while remaining > 0.0 and state in [State.INTRO, State.COUNTDOWN, State.PLAYING]:
		if state == State.PLAYING:
			seconds_left = maxf(0.0, seconds_left - remaining)
			EventBus.round_clock_tick.emit(seconds_left)
			if seconds_left <= 0.0 and state == State.PLAYING:
				_set_state(State.PURGE)
				EventBus.purge_started.emit()
			return
		var used: float = minf(remaining, phase_left)
		phase_left -= used
		remaining -= used
		if phase_left > 0.0:
			return
		if state == State.INTRO:
			phase_left = Balance.get_f("round.countdown_s")
			_set_state(State.COUNTDOWN)
		else:
			_set_state(State.PLAYING)
			EventBus.round_started.emit()
			EventBus.round_clock_tick.emit(seconds_left)


func finish(result: Dictionary) -> bool:
	if state not in [State.PLAYING, State.PURGE]:
		return false
	var snapshot: Dictionary = result.duplicate(true)
	snapshot["domain_id"] = domain_id
	snapshot["round_index"] = round_index
	snapshot["quota"] = quota
	snapshot["seconds_left"] = seconds_left
	_set_state(State.RESULTS)
	EventBus.round_ended.emit(snapshot)
	return true


func _set_state(next: State) -> void:
	state = next
	EventBus.round_state_changed.emit(state)
