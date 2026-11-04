#!/usr/bin/env python3
"""Valida los datos de balance de PURGA.

Uso: python3 scripts/validate_data.py [ruta_repo]
Sale con código 1 si encuentra errores (lo usa la CI).
"""
import json
import math
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
errors: list[str] = []


def load(name: str) -> dict:
    path = ROOT / "data" / name
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        errors.append(f"{name}: no se pudo leer ({exc})")
        return {}


def require(d: dict, dotted: str, src: str) -> object:
    cur: object = d
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            errors.append(f"{src}: falta la clave '{dotted}'")
            return None
        cur = cur[part]
    return cur


balance = load("balance.json")
runners = load("runners.json")

REQUIRED_BALANCE = [
    "round.duration_s", "round.quota_base", "round.quota_max", "round.hub_safe_mode",
    "purge.speed_mps", "purge.hub_close_s",
    "respawn.delay_s", "respawn.spawn_shield_s",
    "damage.directional.front_mult", "damage.directional.rear_mult",
    "weapons.laser.damage_per_shot", "weapons.laser.fire_rate_hz",
    "weapons.laser.ramp_max_mult", "weapons.laser.ramp_time_s",
    "weapons.barrier.drain_per_s", "weapons.missile.damage",
    "weapons.shockwave.radius_m", "weapons.ram.damage",
    "weapons.drainer.damage_per_s", "weapons.ion_whip.stun_s",
    "hazards.fusion_tower.damage_center", "score.kill", "ai.difficulty",
]
for key in REQUIRED_BALANCE:
    require(balance, key, "balance.json")

if require(balance, "round.hub_safe_mode", "balance.json") not in ("always", "round_start", "off", None):
    errors.append("balance.json: round.hub_safe_mode debe ser always | round_start | off")

# Runners
total = runners.get("_meta", {}).get("stat_total", 12)
ids = set()
for r in runners.get("runners", []):
    rid = r.get("id", "?")
    if rid in ids:
        errors.append(f"runners.json: id duplicado '{rid}'")
    ids.add(rid)
    stats = [r.get(k) for k in ("speed", "armor", "handling", "weapons")]
    if any(not isinstance(s, int) or not 1 <= s <= 5 for s in stats):
        errors.append(f"runners.json: '{rid}' tiene stats fuera de 1..5")
    elif sum(stats) != total:
        errors.append(f"runners.json: '{rid}' suma {sum(stats)}, debe sumar {total}")
if len(ids) != 8:
    errors.append(f"runners.json: hay {len(ids)} Runners, deben ser 8")


# Comprobación de TTK de referencia (docs/02 §3): blanco de 100 PI por el costado = 4.67 s
def laser_ttk(hp: float, mult: float = 1.0) -> float:
    lz = balance["weapons"]["laser"]
    dps = lz["damage_per_shot"] * lz["fire_rate_hz"] * mult
    t_r, m = lz["ramp_time_s"], lz["ramp_max_mult"]
    ramp_dmg = dps * t_r * (1 + m) / 2
    if hp <= ramp_dmg:
        a = dps * (m - 1) / (2 * t_r)
        return (-dps + math.sqrt(dps * dps + 4 * a * hp)) / (2 * a)
    return t_r + (hp - ramp_dmg) / (dps * m)


if not errors:
    ttk = laser_ttk(100)
    if not 4.0 <= ttk <= 5.0:
        errors.append(f"balance: TTK láser contra 100 PI = {ttk:.2f} s, fuera de la meta 4–5 s")

if errors:
    print("❌ Errores en los datos:")
    for e in errors:
        print("  -", e)
    sys.exit(1)

print(f"✅ Datos válidos · 8 Runners · TTK láser (100 PI, costado) = {laser_ttk(100):.2f} s")
