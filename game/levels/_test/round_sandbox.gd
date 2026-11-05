extends "res://levels/_test/driving_sandbox.gd"
## Ensayo del ciclo; la Purga anuncia estado, todavía no genera muros letales.

var _portal_driving: bool = false
var _quota_text: String = ""

@onready var portal: RoundPortal = $Portal
@onready var round_manager: RoundManager = $RoundManager
@onready var progress: RoundProgress = $RoundManager/RoundProgress
@onready var round_label: Label = $UI/RoundStatus


func _ready() -> void:
	super._ready()
	EventBus.round_state_changed.connect(_on_round_state)
	EventBus.runner_escaped.connect(_on_escaped)
	$UI/Title.text = "PURGA / ENSAYO DE RONDA"
	$UI/Help.text = "WASD: conducir · Espacio: saltar · Clic/J: láser · Esc: pausa\n" + (
		"Enter: terminar ensayo / siguiente ronda · F7: volver a práctica\n"
		+ "Purga sin muros · Portal a la derecha del inicio · Sin bots ni puntaje de campaña"
	)
	progress.register(runner)
	progress.register(target)
	EventBus.quota_progress_changed.connect(_on_quota_progress)
	round_manager.begin(1, 1)


func _process(delta: float) -> void:
	super._process(delta)
	var clock: int = ceili(round_manager.seconds_left)
	var phase: String = RoundManager.State.keys()[round_manager.state]
	if round_manager.state in [RoundManager.State.INTRO, RoundManager.State.COUNTDOWN]:
		phase += "  %.0f" % ceilf(round_manager.phase_left)
	round_label.text = "D%d · R%d · %s   |   %s   |   %02d:%02d" % [
		round_manager.domain_id, round_manager.round_index, _quota_text,
		phase, clock / 60, clock % 60]
	var warning: bool = round_manager.seconds_left <= Balance.get_f("round.warning_at_s")
	round_label.modulate = Color(1, 0.3, 0.3) if warning else Color(1, 0.85, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F7:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://levels/_test/driving_sandbox.tscn")
			return
		if event.keycode == KEY_ENTER and not get_tree().paused and not portal.is_ascending(runner):
			if round_manager.state == RoundManager.State.RESULTS:
				respawner.cancel()
				runner.reset_at(SPAWN)
				target.reset_at(Vector3(-17, 0.1, 0), PI / 2.0)
				round_manager.begin(1, round_manager.round_index % 3 + 1)
			else:
				round_manager.finish({"reason": "manual_sandbox"})
			return
	if portal.is_ascending(runner) and not event.is_action_pressed("pause"):
		return
	super._unhandled_input(event)


func _on_round_state(state: int) -> void:
	var playing: bool = state in [RoundManager.State.PLAYING, RoundManager.State.PURGE]
	runner.set_physics_process(playing and not portal.is_ascending(runner))
	target.set_physics_process(playing)
	respawner.set_physics_process(state == RoundManager.State.PLAYING)
	if not playing:
		runner.laser.reset()
		target.laser.reset()
	if state == RoundManager.State.PURGE:
		respawner.cancel()


func _on_quota_progress(participant: Runner, kills: int, quota: int) -> void:
	if participant != runner:
		return
	_quota_text = "BAJAS %d / %d%s" % [kills, quota,
		" · CUOTA CUMPLIDA" if kills >= quota else ""]


func _on_escaped(participant: Runner, time_left: float) -> void:
	if participant == runner:
		round_manager.finish({"reason": "escaped", "escape_time_left": time_left})


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if get_tree().paused or "--portal-preview" not in OS.get_cmdline_user_args():
		return
	if progress.has_quota(runner) and not _portal_driving:
		_portal_driving = true
		runner.rotation.y = -PI / 2.0
		runner.input_frame.laser = false
		runner.input_frame.throttle = 0.5
