# 07 · Arquitectura técnica

## 1. Stack

| Pieza | Elección | Motivo |
|---|---|---|
| Motor | **Godot 4.x estable** (fijar la versión menor en `game/project.godot` en M0 y no cambiarla sin issue) | Libre, liviano, corre en GPU integrada |
| Lenguaje | GDScript con **tipado estático** | Curva baja, buen rendimiento con tipos |
| Renderer | `gl_compatibility` | Intel Iris / UHD, equipos modestos |
| Física | Godot Physics (Jolt opcional si la versión lo trae integrado) | — |
| Red (M8) | `MultiplayerAPI` + ENet, servidor autoritativo | Integrado en Godot |
| Datos | JSON en `/data`, cargados por el autoload `Balance` | Balancear sin tocar código |
| Tests | GUT (Godot Unit Test) | Estándar de facto para GDScript |
| CI | GitHub Actions: lint (`gdlint`), validación de JSON, tests GUT headless, export Linux/Windows | — |

## 2. Estructura del repositorio

```
purga/
├── README.md · CONTRIBUTING.md · LICENSE
├── docs/                      # este directorio
├── data/                      # balance.json, runners.json (fuente de verdad)
├── scripts/                   # utilidades (seed_github.sh, validación)
├── .github/                   # plantillas de issues/PR, workflows
└── game/                      # proyecto Godot
    ├── project.godot
    ├── autoload/
    │   ├── event_bus.gd       # señales globales
    │   ├── balance.gd         # carga /data y expone valores tipados
    │   ├── game_state.gd      # campaña: créditos, puntaje, desbloqueos, guardado
    │   └── settings.gd        # opciones de usuario
    ├── core/
    │   ├── damage_info.gd     # clase DamageInfo
    │   ├── input_frame.gd     # clase InputFrame (jugador y bots)
    │   └── enums.gd           # DamageType, RunnerState, AreaId...
    ├── components/            # nodos reutilizables
    │   ├── health_component.gd
    │   ├── weapon_inventory.gd
    │   ├── laser_weapon.gd
    │   ├── barrier_emitter.gd
    │   ├── lock_on_system.gd
    │   └── status_effects.gd  # aturdido, drenado, coraza, camuflaje, escudo de aparición
    ├── entities/
    │   ├── runner/            # runner.tscn, runner.gd, runner_motor.gd, runner_camera.gd
    │   ├── pilot/             # piloto eyectado
    │   ├── projectiles/       # misil, drenador
    │   ├── pickups/           # pickup.tscn + recursos por tipo
    │   └── hazards/           # fusion_tower, purge_wall, magma
    ├── controllers/
    │   ├── player_input.gd
    │   └── bot/               # bot_brain.gd, estados/, percepción
    ├── round/
    │   ├── round_manager.gd   # máquina de estados de la ronda
    │   ├── portal.gd
    │   ├── safe_zone.gd
    │   └── area_tracker.gd
    ├── levels/
    │   ├── _kit/              # piezas modulares
    │   └── domain_01/         # domain_01.tscn, blockout.tscn, nav
    ├── ui/
    │   ├── hud/
    │   ├── menus/
    │   └── theme/             # fuentes, theme.tres
    ├── fx/                    # sprites de fuego, explosiones, shaders
    ├── audio/
    ├── assets/                # modelos y texturas originales + LICENSE-ASSETS.md
    └── tests/                 # GUT
```

**Convenciones:** archivos y carpetas en `snake_case`; clases (`class_name`) en `PascalCase`; código e identificadores en **inglés**, docs y textos de UI en **español** (vía archivos de traducción `.csv` desde M6).

## 3. Autoloads

| Autoload | Responsabilidad | No hace |
|---|---|---|
| `EventBus` | Declara señales globales | Lógica |
| `Balance` | Lee `data/*.json` al arrancar, valida claves y expone `Balance.get_f("laser.damage")`, `Balance.runner("amaru")` | Guardar estado |
| `GameState` | Créditos, puntaje, Dominios y Runners desbloqueados, contraseñas, guardado en `user://save.json` | Lógica de ronda |
| `Settings` | Video, audio, controles, accesibilidad | — |

### Señales de `EventBus`

```gdscript
signal round_intro_started(domain_id: int, round_index: int, quota: int)
signal round_started()
signal round_clock_tick(seconds_left: float)
signal purge_started()
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
signal area_changed(runner: Runner, area_id: int)
signal fusion_tower_detonated(tower: Node3D, trigger: Runner)
signal score_changed(runner: Runner, delta: int, reason: StringName)
```

Regla: los sistemas **emiten** hechos; el HUD, el audio, el puntaje y las estadísticas **escuchan**. Nadie llama directamente al HUD.

## 4. El Runner

```
Runner (CharacterBody3D)          runner.gd: coordina componentes
├── Model (Node3D)                malla + puntos de anclaje
│   ├── Muzzle · RearEmitter · SecondaryMount · PilotEject · CameraTarget
├── CollisionShape3D              caja 1.0 × 0.7 × 2.2 m
├── GroundRays (4 × RayCast3D)    suspensión arcade
├── RunnerMotor                   aceleración, giro, agarre, salto
├── HealthComponent               integridad, aplica DamageInfo
├── StatusEffects                 estados temporales
├── LaserWeapon
├── BarrierEmitter
├── WeaponInventory               3 slots de secundarias
├── LockOnSystem                  fijación de misil y embestida
├── AreaTracker                   en qué área está
└── Controller (PlayerInput o BotBrain) → produce InputFrame
```

- **Física arcade:** `CharacterBody3D` con suspensión por 4 rayos, alineación a la normal del piso, agarre lateral como amortiguación de la velocidad perpendicular. No usar `VehicleBody3D`: es realista y difícil de afinar para este estilo.
- **Separación control/motor:** el Runner solo consume `InputFrame`. Esto permite bots, repeticiones y red con el mismo código.
- **Stats:** `Runner.setup(runner_id)` pide los valores derivados a `Balance` (fórmulas de [03](03_RUNNERS.md)).

## 5. Daño

```gdscript
class_name DamageInfo extends RefCounted
var amount: float
var type: Enums.DamageType   # LASER, MISSILE, SHOCKWAVE, RAM, DRAIN, ION, TOWER, BARRIER, PURGE, MAGMA
var source: Runner           # puede ser null (entorno)
var weapon_id: StringName
var direction: Vector3       # del atacante al blanco
var position: Vector3
```

`HealthComponent.apply(info)` implementa **exactamente** el orden de [02 §2.1](02_COMBATE_Y_BALANCE.md#21-orden-de-aplicación) y registra al último atacante con marca de tiempo para la atribución.

**Explosiones:** `ShapeCast3D` cilíndrico (radio y altura de `balance.json`) + rayo de línea de visión desde el centro hacia cada blanco. Nunca `Area3D` esférica sin comprobar visión.

## 6. Ronda

`RoundManager` es una máquina de estados:

```
LOADING → INTRO → COUNTDOWN → PLAYING → PURGE → RESULTS
                                  └──── (todos escaparon o murieron) ──┘
```

- Calcula la cuota con la fórmula de `balance.json`.
- Abre compuertas según la ronda.
- Lleva el reloj y lo emite a 10 Hz.
- Habilita el `Portal` para cada Runner que cumple la cuota.
- Instancia los `PurgeWall` de cada sala al entrar en `PURGE`.

## 7. Capas de colisión

| Capa | Nombre | Uso |
|---|---|---|
| 1 | `world` | Geometría estática |
| 2 | `runner` | Cuerpos de Runners |
| 3 | `projectile` | Misiles, drenador |
| 4 | `pickup` | Pickups (Area3D) |
| 5 | `hazard` | Torres, magma |
| 6 | `barrier` | Segmentos de barrera |
| 7 | `trigger` | Zona franca, umbrales de área, portal |
| 8 | `purge` | Muro de la Purga |
| 9 | `pilot` | Piloto eyectado |

## 8. Rendimiento (presupuesto en GPU integrada, 60 fps)

| Recurso | Presupuesto |
|---|---|
| Triángulos en pantalla | ≤ 80 k |
| Draw calls | ≤ 300 |
| Luces dinámicas | ≤ 4 a la vez (explosiones), el resto horneado |
| Partículas | Sprites billboard; ≤ 400 partículas activas |
| Segmentos de barrera | Pool de 256; mallas fusionadas por Runner |
| Física | 60 Hz; los bots piensan a 30 Hz, escalonados |
| Render interno | 640×360 con escalado *nearest* (modo retro, por defecto) o nativo |

Medir con el monitor de Godot y un *benchmark* reproducible: `game/tests/bench_domain01.tscn` (8 bots, 60 s, registra fps mín./medio).

## 9. Red (M8, adelanto para no cerrarse puertas)

- Servidor autoritativo: los clientes envían `InputFrame`, el servidor simula y difunde estado a 30 Hz.
- Predicción local del propio Runner, interpolación de los demás (100 ms).
- Toda aleatoriedad pasa por un RNG con semilla de la ronda.
- Por eso desde M1: **nada de lógica de juego en el HUD ni en la cámara**, y el Runner solo lee `InputFrame`.

## 10. Guardado

`user://save.json`, versión de esquema incluida:

```json
{ "schema": 1, "credits": 3, "score": 0, "unlocked_domains": [1], "unlocked_runners": ["amaru","puma","chikchi","wikuna"], "best_scores": [] }
```

Las contraseñas codifican Dominio alcanzado y créditos (algoritmo en `game_state.gd`, documentado en el código).
