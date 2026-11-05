extends "res://levels/_test/driving_sandbox.gd"
## Ensayo del ciclo; la Purga anuncia estado, todavía no genera muros letales.

@onready var round_manager: RoundManager = $RoundManager
@onready var round_label: Label = $UI/RoundStatus


func _ready() -> void:
	super._ready()
	EventBus.round_state_changed.connect(_on_round_state)
	$UI/Title.text = "PURGA / ENSAYO DE RONDA"
	$UI/Help.text = "WASD: conducir · Espacio: saltar · Clic/J: láser · Esc: pausa\n" + (
		"Enter: terminar ensayo / siguiente ronda · F7: volver a práctica\n"
		+ "Purga sin muros · Cuota informativa · Sin portal, bots ni puntaje de campaña"
	)
	round_manager.begin(1, 1)


func _process(delta: float) -> void:
	super._process(delta)
	var clock: int = ceili(round_manager.seconds_left)
	var phase: String = RoundManager.State.keys()[round_manager.state]
	if round_manager.state in [RoundManager.State.INTRO, RoundManager.State.COUNTDOWN]:
		phase += "  %.0f" % ceilf(round_manager.phase_left)
	round_label.text = "D%d · R%d · CUOTA %d   |   %s   |   %02d:%02d" % [
		round_manager.domain_id, round_manager.round_index, round_manager.quota,
		phase, clock / 60, clock % 60]
	var warning: bool = round_manager.seconds_left <= Balance.get_f("round.warning_at_s")
	round_label.modulate = Color(1, 0.3, 0.3) if warning else Color(1, 0.85, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F7:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://levels/_test/driving_sandbox.tscn")
			return
		if event.keycode == KEY_ENTER and not get_tree().paused:
			if round_manager.state == RoundManager.State.RESULTS:
				respawner.cancel()
				runner.reset_at(SPAWN)
				target.reset_at(Vector3(-17, 0.1, 0), PI / 2.0)
				round_manager.begin(1, round_manager.round_index % 3 + 1)
			else:
				round_manager.finish({"reason": "manual_sandbox"})
			return
	super._unhandled_input(event)


func _on_round_state(state: int) -> void:
	var playing: bool = state == RoundManager.State.PLAYING
	runner.set_physics_process(playing)
	target.set_physics_process(playing)
	respawner.set_physics_process(playing)
	if not playing:
		runner.laser.reset()
		target.laser.reset()
	if state == RoundManager.State.PURGE:
		respawner.cancel()
