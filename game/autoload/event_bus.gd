extends Node
## Hechos globales; sin lógica de gameplay.

signal round_intro_started(domain_id: int, round_index: int, quota: int)
signal round_state_changed(state: int)
signal round_started()
signal round_clock_tick(seconds_left: float)
signal purge_started()
signal purge_closed()
signal quota_progress_changed(runner: Runner, kills: int, quota: int)
signal quota_reached(runner: Runner)
signal runner_escaped(runner: Runner, time_left: float)
signal round_ended(result: Dictionary)

signal runner_damaged(victim: Runner, info: DamageInfo, remaining: float)
signal runner_destroyed(victim: Runner, killer: Runner, weapon_id: StringName)
signal pilot_ejected(pilot: Node3D, owner: Runner)
signal mercy_kill(killer: Runner, victim_owner: Runner)
signal runner_respawned(runner: Runner)

signal lock_started(attacker: Runner, target: Runner, weapon_id: StringName)
signal lock_lost(attacker: Runner, target: Runner)
signal pickup_collected(runner: Runner, pickup_id: StringName)
signal inventory_changed(runner: Runner)
signal area_changed(runner: Runner, area_id: int)
signal fusion_tower_detonated(tower: Node3D, trigger: Runner)
signal score_changed(runner: Runner, delta: int, reason: StringName)
