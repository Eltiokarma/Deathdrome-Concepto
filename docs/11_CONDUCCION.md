# Prototipo de conducción — M1

## Abrir

Godot 4.6.3.stable. Desde la raíz: `python3 scripts/prepare_data.py`, abrir `game/project.godot` y F5. La escena principal es `levels/_test/driving_sandbox.tscn`. La vista orbital anterior sigue disponible en `levels/_test/test_arena.tscn` (F6).

## Controles implementados

| Acción | Teclado | Mando |
|---|---|---|
| Acelerar / frenar | W / S | RT / LT |
| Girar | A / D | Stick izquierdo |
| Saltar | Espacio | A |
| Cámara cercana / lejana / cabina | C | D-pad arriba |
| Mirar atrás | V mantenido | Clic stick derecho |
| Pausar / continuar | Esc | Start |
| Cambiar Runner (los ocho) | F2 | — |
| Valores derivados / diagnóstico | F3 | — |
| Reubicar en salida | R | — |

S frena: no hay marcha atrás. F2, F3 y R son herramientas del banco de pruebas, no controles definitivos de campaña. Se puede girar detenido para salir de una pared. El láser ya funciona con clic izquierdo/J/RB; las secundarias, barrera y radar siguen pendientes. El Runner de ensayo no tiene IA; R restaura ambos vehículos y cancela la reaparición pendiente.

## Arquitectura

`PlayerInput → InputFrame → Runner → RunnerMotor`. El Runner consume el mismo frame si procede de teclado/mando, de una prueba o del recorrido de demostración. InputFrame sanea valores no finitos y limita los ejes. EventBus tiene las señales tipadas del documento de arquitectura; DamageInfo es solo un contrato, sin aplicación de daño.

Runner usa CharacterBody3D, colisión 1 × 0,7 × 2,2 m y las estadísticas de Balance. El motor proyecta la velocidad sobre el suelo, amortigua deriva lateral y usa colisiones barridas de move_and_slide. Cuatro rayos calculan la pose visual del vehículo sobre pendientes. **Esto aún no es una suspensión física de cuatro apoyos:** el casco permanece vertical y la malla se inclina. El feel y esa suspensión quedan para revisión de PUR-011.

La cámara usa SpringArm3D con una esfera de 0,2 m; excluye el propio vehículo y colisiona con mundo/barreras. Modo cercano: desplazamiento (0, 1,4, 3,6) m, inclinación −7°, FOV vertical 60°. Los otros modos y la respuesta de seguimiento están en Balance. Cabina oculta la malla propia.

## Parámetros nuevos de prototipo

No se cambian las estadísticas originales ni el salto de 2,5 m, recarga 1,2 s y control aéreo 20 %. Se añaden parámetros necesarios para probar el motor:

| Ruta en Balance | Valor inicial |
|---|---:|
| movement.gravity_mps2 | 20 |
| movement.brake_mult | 2,5 |
| movement.coast_mult | 0,35 |
| movement.grip_damping | 10 |
| movement.pose_response | 12 |
| movement.floor_max_angle_deg | 30 |
| movement.floor_snap_m | 0,4 |
| camera.turn_response | 10 |

Son valores de prototipo, sujetos a playtest. Los parámetros de cámara también viven en `data/balance.json`.

## Verificación

`python3 scripts/check_project.py` ejecuta las pruebas GUT existentes y las nuevas de aceleración/freno, salto/apogeo, doble salto, rampa de 25°, descenso lento de cornisa, pared, cambio de stats y cámara ante pared. Hay comprobaciones de mapeos, entradas simultáneas de teclado/mando y pausa. El paquete se exporta y arranca desde un directorio sin fuentes.

CI publica `combat-prototype-preview`: vista orbital y recorrido automático real en Godot. La demostración se reproduce con `godot --path game -- --driving-preview`; el movimiento se inyecta como InputFrame, no como animación de posición.

## Playtest pendiente para Opus / Gerson

- Comparar Kuntur y Lloqlla con F2; ajustar aceleración, frenado y respuesta de giro con sensación real.
- Subir ambas rampas a varias velocidades, frenar arriba y descender por el borde de la plataforma.
- Probar salto cerca del muro y bajo el techo, cada cámara y mirar atrás en pasillos.
- Verificar un mando físico; los tests de entrada usan eventos sintéticos.
- Medir GPU integrada. El render de CI es por software y no demuestra 120 fps.

Salud y láser se añadieron en PUR-020/021. No hay bots, rondas, retro-render ni red. No declarar cerrado PUR-011/PUR-014 solo por los tests de regresión: requieren playtest de conducción y cámara.


## Ciclo automático del blanco de ensayo

Al destruir el blanco, `PracticeRespawner` espera `respawn.delay_s` (4 s) y lo restaura con `respawn.spawn_shield_s` (3 s). El contador de bajas se conserva. La pantalla muestra cuenta atrás, escudo o punto ocupado. Si el jugador se coloca en la aparición, el blanco espera a que se despeje; no se teletransporta dentro de otro Runner. Esc congela el temporizador. R reinicia de inmediato y cancela el ciclo pendiente.

Prueba manual: mantener J hasta destruir; observar cuenta atrás y escudo; disparar durante el escudo no reduce integridad. Repetir pausando durante la cuenta atrás. Para bloqueo, destruir y conducir al punto antes de que termine la espera, después apartarse.

Este servicio está restringido al sandbox y comprueba ocupación por Runners en un punto fijo conocido. No es el respawn de ronda: no gestiona créditos, Purga, IA, selección de puntos ni peligros. Al implementar RoundManager, definir una política propia en lugar de reutilizarlo sin esas reglas.

Las entradas de daño nulas/no finitas se rechazan sin tocar salud ni atribución. Al morir, el estado `destroyed` se fija antes de emitir `runner_damaged`, evitando una segunda aplicación letal desde un callback de ese evento. Los listeners no deben reiniciar el Runner dentro de ese callback; usar un controlador de ciclo de vida después del evento de destrucción.


## Ensayo de ronda (F7)

F7 abre un ensayo de RoundManager sobre la misma arena. Intro de 4 s con cuota, cuenta de 3 s y reloj de 5:00. Durante intro/cuenta no se conduce; en PLAYING funcionan los controles de práctica. Al agotarse el reloj se anuncia PURGE y se desactiva el respawn, pero se puede conducir al portal: **todavía no hay muros de Purga**. Enter finaliza manualmente y muestra RESULTS; otro Enter avanza R1 → R2 → R3 → R1. F7 vuelve a práctica. Esc pausa también las cuentas.

La cuota ya cuenta bajas atribuidas de los participantes registrados, incluso durante PURGE. El HUD muestra progreso y CUOTA CUMPLIDA; el portal de ensayo ya permite salida y ascenso. Sin bots ni campaña. `round_manager.gd` no decide quién gana ni cuánto dura la Purga: el futuro nivel llama `finish(result)`. Los eventos se publican en EventBus. La escena puede abrirse directamente: `godot --path game --scene res://levels/_test/round_sandbox.tscn`.


### Portal de ensayo

En F7, cumple la cuota y conduce hacia el podio a la derecha del inicio (`x=0, z=15`). Cerrado es sólido; al cumplir la cuota su anillo toma tu color y puedes entrar. El control pasa a un ascenso de 3 s por túnel octogonal; la salida guarda el tiempo de entrada y lleva a RESULTS. Enter inicia la siguiente ronda. Esc pausa; no se permite R/F2/Enter durante el ascenso. El podio conserva colisión para Runners sin cuota.

La escena sigue siendo un prototipo de un jugador con blanco inmóvil, sin zona franca física ni muros de Purga. El futuro nivel decidirá resultados multijugador; el portal publica `runner_escaped`, no concede puntaje ni créditos.
