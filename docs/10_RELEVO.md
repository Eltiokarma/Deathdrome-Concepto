# Relevo de trabajo — Codex / Claude

## 2026-11-06 · Inventario y pickups (PUR-040)

- **`InventoryComponent`** en cada Runner: 3 slots repetibles, Q/E por `InputFrame.cycle_secondary`, `take_selected()` para las armas futuras. Se vacía en `reset_at`, o sea al reaparecer. Nueva señal `EventBus.inventory_changed`.
- **`Pickup`:** flota y gira. Arma: 20 s. Orbe de salud: +35 PI sin pasar el máximo, solo si hay daño, 25 s. `HealthComponent.heal()`.
- **Greybox:** las reservas M (misil) y H (salud) del Dominio 1 ya son pickups reales. Las torres (T) siguen como marcadores hasta PUR-044. M3 de la sala 1 pasa a la cima del mirador central.
- **Pendiente:** el botón secundario aún no dispara nada; el misil es PUR-041/042.
- **Verificado en local:** **135 pruebas**, lint, datos y paquete.

---

## 2026-11-06 · Tres niveles de altura por sala y tiro en marcha (pedido de Gerson)

**Reaparición:** Gerson recuerda que se reaparece «en el centro, donde se inicia». Ya es así: los 8 puntos de aparición están a 7 m del portal, igual que al empezar la ronda. No se cambió.

**Alturas:**
- Miradores a +6 m en las cuatro salas (`decks`), con rampas que arrancan a +3 m.
- Más rampas suelo → +3.
- Sala 4: puestos de vigilancia nuevos en las esquinas del fondo.
- Prueba nueva `test_three_height_levels_per_room_with_continuous_ramps`.

**Tiro en marcha:**
- `--strafe-preview`: ronda 2, sala 3, tres blancos.
- El piloto automático dispara mientras conduce cuando el auto-apuntado tiene blanco y modera el acelerador a 0.6. Solo frena para rematar si un blanco sobrevive a la pasada.
- Las tres bajas, a 12–14 m/s.
- Prueba nueva en `test_domain_rounds.gd`.

**Láser:** el rayo se dibuja como prisma de 0.12 m; la línea de 1 px no se veía en video. Dura un periodo de disparo, así que el fuego sostenido se ve continuo. Solo visual.

**Verificado en local:** **127 pruebas**, lint, datos y paquete.

---

## 2026-11-06 · Muerte, pira, piloto y reaparición de ronda (PUR-023/024)

**Nuevo:**
- **`entities/pilot/pilot.gd` (+ `.tscn`):** 10 PI; huye del atacante a 6 m/s durante 2.5 s y después lo recogen. Si lo derriban emite `mercy_kill`. Sin colisión con Runners y respeta la zona franca.
- **`entities/fx/pyre.gd`:** destello y pira animada por código durante 6 s.
- **`round/death_sequence.gd`:** pira + piloto en cada muerte; las muertes por Purga no eyectan piloto.
- **`round/round_respawner.gd`:**
  - 4 s (+2 s con mercy kill) hasta un punto de aparición libre del hub, con escudo de 3 s;
  - nada durante la Purga;
  - los caídos vuelven al empezar cada ronda.
- **`laser_weapon.gd`:** `acquire_pilot()`. Solo apunta pilotos si no hay Runner en la mira; los Runners no cambian.

**Escena del greybox:**
- `--death-preview`: un blanco artillado derriba al jugador y remata a su piloto.
- La caza de blancos ignora a los que reaparecen (cuenta la vida en la que se derribaron).
- El HUD muestra DESTRUIDO con la cuenta atrás y el escudo.

**Verificado en local:** **125 pruebas / 910 aserciones**, lint, datos y paquete.
- Muerte a los 6.5 s, piloto rematado a los 7.4 s, reaparición a los 12.5 s (+6.0 s).

**Pendiente:**
- Sprite de arte de la pira.
- Control del piloto por el jugador.
- Vaciado de slots, cuando exista el inventario (PUR-040).

---

## 2026-11-06 · Portal, cuota y puntaje en el Dominio 1

**Integración en la escena del greybox:** se reutilizan sin cambios `RoundPortal` (PUR-033), `RoundProgress`, `RoundScore` (PUR-035) y `SafeZone` (PUR-031).
- **Portal:** en la cima del podio.
- **Zona franca:** el hub completo, Ø120 m.
- **Cuota:** el jugador queda registrado como participante.

**Blancos de práctica:** `spawn_targets()` crea Runners quietos que participan en la ronda, así que sus bajas cuentan para la cuota.

**Vistas previas:**
- `--quota-preview`: entra en la sala 1, derriba dos blancos con el láser (12.6 s), vuelve y asciende por el portal a los 29 s.
- `--purge-preview`: la cuota se cumple de antemano por la vía normal de daño y el Runner huye por el portal (19.7 s).

**Rutas de exploración:** sin cuota, la barrera del portal impide subir a la cima. Ahora terminan al pie del portal (evento «llega al portal»).

**Verificado en local:** **121 pruebas / 880 aserciones**, lint, datos y paquete.

**Pendiente:**
- Respawn de ronda (PUR-023/024).
- Inventario y pickups reales (PUR-040).
- Bots (PUR-050+): hoy solo hay blancos quietos.

---

## 2026-11-06 · Áreas, compuertas por ronda y Purga por salas (PUR-032, 036, 034)

**Nuevo en `game/round/`:**
- **`area_tracker.gd`:** `area_changed` una vez por cruce; hay que penetrar 1 m en el área nueva, así que oscilar en el umbral no emite nada.
- **`gate_controller.gd`:** abre según `round.open_areas_by_round`. Añade `Balance.get_a()` para leer arrays.
- **`domain_purge_field.gd` (+ `.tscn`):** hereda de `PurgeField`, que ahora separa `_advance()` de la aplicación del daño, sin cambio de comportamiento. Un frente por sala desde el muro de fondo, después el cierre del hub. Las salas con compuerta cerrada son letales desde el inicio.

**Greybox:**
- `area_at(point, inset)`, `area_far_edge()`.
- Compuertas `GateN`: losa roja, luz roja, `set_gate_open`.
- En la escena:
  - `--round=N` activa reloj, compuertas y Purga;
  - `--purge-preview` muestra la huida desde el fondo de la sala 1;
  - F7 pasa a la ronda siguiente.

**Verificado en local:** **120 pruebas / 873 aserciones**, lint, datos y paquete.

**Pendiente:**
- Portal real en esta escena (PUR-033 existe en el sandbox de ronda). Ahora llegar al podio en la vista previa cuenta como escapar.
- Respawn de ronda (PUR-023/024), inventario/pickups (PUR-040), bots (PUR-050+).

---

## 2026-11-06 · Alcances a escala ×6 y salas 2–4 del Penal Altiplano

**Alcances (pedido de Gerson):**
- Visión de bots: 60 → **150 m**.
- Radar: 60 → **150 m**, solo en docs porque el HUD aún no existe.
- Fijación de misil: 70 → **175 m**, con vida del misil de 4 → **6 s** para que alcance a volar esa distancia.
- Docs 02, 05, 06 y 08 actualizados.

**Salas 2–4:**
- Construidas en el greybox (`LARGE_ROOMS`); las cuatro salas y conexiones abiertas, porque las compuertas por ronda (PUR-036) siguen pendientes.
- `room_layout(gate)`, `room_point(u, d, gate)` y `corridor_point()` generalizan la construcción.
- Rutas `--route-2/3/4` en la escena de prueba.
- Ficha con tabla, planos SVG por sala y resultados.

**Verificado en local:** **115 pruebas / 807 aserciones**, lint, datos y paquete.
- Recta libre máxima del dominio: 220.5 m.
- Rutas de las salas 2/3/4: 45/50/39 s.

**Siguiente bloque sugerido:**
- compuertas por ronda (PUR-036) y AreaTracker (PUR-032) sobre esta escena;
- después, Purga por salas (PUR-034) con 10 m/s.

---

## 2026-11-06 · Escala ×6 oficial, láser 150 m y Purga 10 m/s (decisión de Gerson)

**Decisión:** Gerson adoptó como oficial la sala grande (×6 en largo, hub ×3) y pidió subir láser y Purga.

**Cambios:**
- `balance.json`:
  - `weapons.laser.range_m` 60 → **150**;
  - `purge.speed_mps` 3.5 → **10** (15 en D8, por debajo del Runner más lento, 18.5 m/s).
- Greybox: `layout_scale = 6`, `hub_scale = 3` por defecto. La escala ×1 sigue disponible con `--layout-scale=1 --hub-scale=1`.
- Pruebas reescritas para la escala oficial. `test_purge` y `test_combat` leen ahora la velocidad y el alcance de `Balance` en vez de números fijos.
- Pilares de 4 × 4 m: con 2 × 2 m una diagonal de 241 m superaba la métrica.
- `check_project.py` corre GUT con `--fixed-fps 60`: las rutas simuladas tardan segundos, no minutos.
- Docs actualizados: 01, 02, 04 (métricas nuevas: línea ≤ 1.5 × láser), 08, 11, ficha y SVG. La CI graba la ruta A completa.

**Verificado en local:**
- **113 pruebas / 709 aserciones**, lint, datos y paquete.
- Recta libre máxima: 219.5 m.
- Rutas: A 52 s y B 43 s.

**Pendiente o a decidir (no tocado):**
- **Alcances que siguen en 60–70 m:**
  - visión de bots (`ai.vision_range_m` 60, docs/06);
  - radar (60 m, docs/05);
  - fijación de misil (70 m).

  Conviene revisarlos con la nueva escala; no se cambiaron porque no se pidió.
- **Salas 2–4:** necesitan interior a la nueva escala.
- **Playtest:** encuentros con 8 Runners y rendimiento.

---

## 2026-11-06 · Prototipo grande de la sala 1 (escala ×6 en largo, pedido por Gerson)

Gerson revisó la prueba a ×2.45 y pidió **otro ×2.45 (≈ ×6 en largo, ≈ ×36 en superficie)**, **llenando el espacio**. Aportó capturas del original como referencia de escala (salas-nave abiertas, techos altos, pasarelas elevadas perimetrales); se usan solo para escala, según las reglas clean-room.

**Implementado:**
- Uso: `--layout-scale=6 --hub-scale=3` (o variables `PURGA_LAYOUT_SCALE` / `PURGA_HUB_SCALE`).
- Con escala ≥ 3 la sala 1 usa un interior propio de **216 × 216 m** con techo de 12 m:
  - deflector a la entrada;
  - campo de pilares 2 × 2 m con calles de 12 m;
  - plataforma central de 40 × 40 m a +3 m con cuatro rampas;
  - muros bajos de 1.2 m (saltables) y bloques;
  - pasarelas perimetrales a +3 m con rampas;
  - tres cámaras al fondo tras un muro con tres huecos de 16 m.
- Hub Ø120 m; conexiones de 84 m.
- Por defecto todo sigue en escala 1: ficha, pruebas y balance sin cambios.

**Medido:**
- Ruta A (pasarelas, plataforma, cámaras): 52 s.
- Ruta B (suelo): 43 s.
- Sala 1 a 7.1 s del spawn.
- Sin roces salvo el pie de la rampa del podio.
- Reservas ocultas al hub.
- **Línea libre más larga: 223 m**, frente a 60 m del láser.

**Pendiente de decisión de Gerson:** si se adopta esta escala, actualizar `docs/04` (métricas), la ficha y el balance. Afecta a:
- alcance del láser/misil (o aceptar líneas largas sin daño);
- velocidad de Purga (a 3.5 m/s barrer 216 m tarda ~62 s);
- cuotas y encuentros con 8 Runners;
- rendimiento.

---

## 2026-11-06 · Prueba de escala pedida por Gerson (sin decisión todavía)

Gerson recuerda los mapas del original como unas **6 veces más grandes en superficie** (≈2.45× en largo). El greybox acepta ahora `layout_scale` (`--layout-scale=2.45` o `PURGA_LAYOUT_SCALE=2.45`). Escala la planta y conserva anchos de paso, alturas, pendientes, podio y portal. Por defecto vale 1.0: ficha, pruebas y balance no cambian.

**Medido a ×2.45:**
- Sala 1 a 4.4 s del spawn (antes 2.4 s); vuelta completa de las rutas en 20–22 s (antes 11).
- Línea libre más larga: 151 m frente a 60 m de alcance del láser.
- Reservas siguen ocultas al hub.
- Coberturas quedan a ~30 m entre sí: la sala se ve vacía.

**Pendiente de decisión de diseño de Gerson** antes de tocar `docs/04` o `balance.json`. Cosas que cambiarían: métricas de sala/hub/línea máxima, alcance del láser o cantidad de coberturas, velocidad de Purga, cuotas y rendimiento.

---

## 2026-11-06 · Claude: greybox hub + sala 1 (PUR-070 rev. 3, avance de PUR-071)

**Rama:** `claude/determined-heisenberg-jj3o54` (misma PR que la rev. 2).
**Archivos nuevos:**
- `game/levels/domain_01/penal_altiplano_greybox.gd`: geometría generada desde constantes, que son las mismas cotas de la ficha.
- `game/levels/domain_01/penal_altiplano_sandbox.{gd,tscn}`: escena jugable, piloto automático `--route-a`/`--route-b` y vista aérea `--overview-preview`.
- `game/tests/test_domain_01_greybox.gd`: 7 pruebas.

**Archivos modificados:** ficha, SVG y CI (graba un video de la ruta A).

**Hallazgos físicos que corrigieron el plano:**
- El deflector a 6 m era imposible de esquivar a velocidad máxima (radio de giro de 10–13 m). Pasó a 8 m, que se sostiene porque las rampas del podio también cortan líneas.
- Paso de 2 m entre el deflector y la rampa RA: P1 y RA retroceden 2 m.
- Juntas de suelo solapadas enganchaban al Runner: ahora hay un único suelo de colisión.

**Verificado:** suite completa en local con Godot 4.6.3: **112 pruebas / 679 aserciones**, lint, datos y paquete. Las cifras de líneas, rutas y spawns están en la ficha.

**Sin verificar:**
- playtest humano de la frenada ante D1;
- salto sobre el podio;
- torres reales, bots, rendimiento con ocho Runners;
- salas 2–4.

PUR-071 **no** está terminado.

**Siguiente bloque sugerido:** interiores de las salas 2 y 3 con el mismo método (plano → comprobación 2D → greybox → pruebas). En paralelo, AreaTracker PUR-032 sobre esta escena.

---

## 2026-11-06 · Claude: PUR-070 rev. 2 (hub, podio y sala 1)

**Rama:** `claude/determined-heisenberg-jj3o54`, partiendo de `main` en `3dc5618`. **Archivos:** `docs/dominios/01_penal_altiplano.md`, `docs/dominios/img/01_penal_altiplano.svg` y esta nota. Entrega solo documental: no cambia código ni balance.

**Decisiones:**
- Rampas del podio en los cuatro ejes cardinales, 4 × 4.5 m, 18.4°.
- Spawns pasan de ±22.5° a **±30°**: con ±22.5° la huella del Runner se solapaba con la rampa (−0.2 m); ahora quedan 0.52 m libres.
- Hub con techo de 6 m y óculo Ø12 sobre el portal (el ascenso de 12 m no cabía bajo 5 m).
- Sala 1: deflector de 20 × 2 m a 6 m de la entrada, plataforma oeste +2 m con rampa de 8 m, pilares C1 y C2, torres T1 y T2, reservas M1–M3 y H1, y dos rutas en lazo.

**Verificado (en planta, por muestreo en 2D):**
- Línea libre máxima de 59.4 m. Con el deflector 1–2 m más adentro daba 60.4–61.5 m.
- Ninguna torre ni pickup visible desde el hub.
- Anchos de 7–9 m, pendientes y separación de coberturas: valores en la ficha.

No se ejecutó la suite del juego (no hay cambios de código).

**Sin verificar:** giro en los 6 m antes del deflector, disparo saltando sobre el podio, colisiones reales y navegación. Salas 2–4 sin interior.

**Siguiente bloque:** greybox del hub + sala 1 en una escena separada. No declarar PUR-071 terminado.

---

## 2026-11-05 · Relevo para el próximo avance pequeño de Claude

**Pedido de Gerson:** dejar todo anotado y permitir un avance pequeño, cuidando el consumo de tokens. Codex termina aquí; no mantiene tareas reservadas ni trabajo en segundo plano.

### Estado al entregar
- Código de Purga integrado por PR #12; última verificación de gameplay: 105 pruebas / 612 aserciones y CI correcta. No se han ejecutado nuevas pruebas del juego por los cambios documentales posteriores.
- Ficha y plano inicial del Dominio 1 publicados en `main`, commit `5c522eb4962105924d81a1410d40866b746bfb12`. Son propuesta, no geometría construida.
- Leer primero [ficha PUR-070](dominios/01_penal_altiplano.md), [plano SVG](dominios/img/01_penal_altiplano.svg) y métricas de [docs/04](04_DOMINIOS_Y_NIVELES.md). La lista completa de pendientes está debajo; las entradas antiguas son historial.

### Siguiente entrega sugerida: cerrar detalles del plano, sin ampliar alcance
1. Actualizar desde `main` y comprobar PRs/reservas existentes. Registrar aquí la rama y los archivos tomados.
2. Revisar la propuesta PUR-070 y concretar **solo el hub, su acceso al podio y el interior de la sala 1**: coordenadas de rampas, deflectores, reservas de torres/pickups y dos rutas de paso.
3. Actualizar ficha y SVG juntos. Comprobar sobre el plano anchos, pendientes, espacio entre spawns/podio y corte de rectas a ≤60 m; señalar como pendientes las comprobaciones físicas. No extrapolar esa revisión a las cuatro salas.
4. Entregar un PR documental breve con decisiones, medidas y pendientes. No implementar todavía bots, arsenal, compuertas ni toda la geometría del dominio en esta entrega.
5. Terminar dejando aquí PR/commit, qué se verificó y cuál sería el siguiente bloque: greybox del hub + sala 1 en una escena separada. No declarar PUR-071 terminado.

**Cuidado:** los tiempos de la ficha son ideales a velocidad constante; las posiciones interiores, cobertura real de Purga, navegación y rendimiento todavía no están validados. Mantener el sandbox existente y los valores de Balance. Si la revisión descubre incompatibilidades, documentarlas y corregir el plano antes de construir.

Esta nota es el canal de coordinación; no implica que Claude ya haya leído o aceptado la tarea.

---

## 2026-11-05 · Propuesta de plano PUR-070 preparada por Codex

Para reducir trabajo de Claude se añadió [ficha del Penal Altiplano](dominios/01_penal_altiplano.md) y plano SVG de implantación. Incluye dimensiones, conexiones, aperturas por ronda, reservas de contenido, tiempos ideales y contrato propuesto de Purga. No cambia código ni balance.

**La recomendación anterior de empezar el plano desde cero queda sustituida:** Claude debe revisar esta propuesta, concretar interiores/deflectores y pasar al blockout por entregas. PUR-070 queda como propuesta documental pendiente de aprobación de diseño; no confundir el plano con geometría validada. No hay tareas reservadas. Revisión documental de medidas y enlaces; no se repite la suite del juego por esta entrega documental.

## 2026-11-05 · Pendientes vigentes y guía para Claude

**Punto de partida:** `main` en `79d5890744e576b9fa424a55e7b30ab3c7389005`, PR #12 integrado. Esta lista sustituye las recomendaciones de “siguiente bloque” de las entradas históricas inferiores. Es un inventario de implementación y validación, no una declaración de cierre de todos los criterios del roadmap.

### Lo que ya funciona y debe conservarse

Conducción de los ocho Runners con stats, salto y cámaras; salud/atribución; láser y barrera; blanco de práctica con reaparición; estados/reloj de ronda; cuota individual; portal selectivo con ascenso; zona franca; puntaje de sesión; Purga radial letal de ensayo. CI verificada en PR #12: **105 pruebas / 612 aserciones**, lint, importación, exportación y ejecución del PCK. Video real revisado: frente radial, muerte y RESULTS. Estos resultados no certifican mando físico, rendimiento real ni una partida completa contra siete bots.

### Orden recomendado de trabajo (una entrega acotada cada vez)

| Prioridad | Bloque / IDs | Qué falta y cómo comprobarlo |
|---|---|---|
| 1 | Dominio 1: plano, áreas y compuertas — PUR-070, 032, 036, 071 | Crear ficha/plano de Penal Altiplano; después hub y cuatro salas con métricas del diseño, umbrales sin parpadeo y aperturas R1:1–2 / R2:+3 / R3:+4. Validar recorridos, colisiones y futura navegación. No sustituir toda la arena en el mismo PR del plano. |
| 2 | Muerte y reaparición de ronda — PUR-023/024 | Piloto de 10 PI, ventana de 2.5 s, mercy kill, explosión/pira de 6 s. Después respawn real en hub a 4 s o 6 s tras mercy kill; escudo 3 s, integridad/barrera llenas, slots vacíos cuando exista inventario. Probar atribución, pausa y prohibición de respawn en Purga. PracticeRespawner no es el sistema definitivo. |
| 3 | Inventario y pickups — PUR-040 | Tres slots repetibles, selección Q/E, rechazo cuando están llenos y reaparición de pickups a 20 s. Es dependencia del BotBrain previsto; no declarar completa IA antes de resolverla. |
| 4 | Primer rival y luego siete bots — PUR-050/051/052/055 | Empezar por percepción y un bot que produzca InputFrame; después navegación, combate, búsqueda de armas y escape/Purga. Añadir depuración F4/log. Ampliar a siete y medir escapes en 20 rondas (objetivo ≥90% para bots con cuota). PUR-053/054 requieren además torres/tácticas; no cerrar toda IA con un perseguidor sencillo. |
| 5 | Purga del dominio — completar PUR-034 | Adaptar frentes a salas/compuertas y cubrir todo volumen jugable sin refugios accidentales, manteniendo 3.5 m/s, cierre del hub en 10 s y D8 ×1.5. El radial actual sigue disponible como ensayo. Depende de disponer de geometría real. |
| 6 | Arsenal y peligros — PUR-041–048 | Fijación, misil, onda, torres, embestida, drenador, látigo e ítems. Seguir dependencias del roadmap, pruebas de línea de visión, zona franca, atribución y salto sobre onda/torre. |
| 7 | Interfaz y campaña — PUR-025, 060–066 | Separar HUD de presentación del controlador de ensayo; HUD completo, mensajes, radar, menús, resumen desglosado, créditos/Game Over, guardado versionado y contraseñas. Puntaje actual solo vive en la instancia de sesión. Accesibilidad y traducción pendientes. |
| 8 | Arte, audio y demostración pública — PUR-015, 072–075 | Render retro conmutable, modelos/kit modular, VFX y audio completo (solo hay aviso sintético de Purga). Registrar licencias. Benchmark en GPU objetivo con ocho Runners y playtest ≥5 personas / ≥20 rondas antes de declarar vertical slice. |
| Después | LAN y dominios restantes — PUR-080–083, 090–096 | Servidor/lobby/sincronización y dominios 2–8, después de validar la demo y sus dependencias. No son tareas de acabado menores. |

### Implementado parcialmente o pendiente de validación

- **PUR-005/011/014:** greybox, conducción y cámaras utilizables; faltan medición en GPU integrada, suspensión completa/feel y playtest de cámaras. Las cuatro sondas actuales inclinan la malla, no equivalen a suspensión física del casco.
- **PUR-010:** entrada de teclado/mando cubierta con pruebas sintéticas; falta mando físico.
- **PUR-022:** barrera funcional y probada; falta playtest de esquiva/salto y coste real con ocho Runners.
- **PUR-031/033:** zona franca y portal funcionan en ensayo; integrar dimensiones y accesos en el dominio, pulir túnel/cámara/arte.
- **PUR-035:** reglas de puntaje y cuotas implementadas; mercy kill tiene tratamiento probado pero carece de piloto/emisor jugable, y el bonus de torre espera a la torre. Falta persistencia de campaña.
- **PUR-030/034:** ciclo de ensayo y Purga funcionales; todavía no representan una ronda completa con ocho participantes y progresión de campaña.

### Instrucciones de coordinación para Claude / Codex

1. Leer esta sección, `docs/08_ROADMAP.md` y los documentos de diseño del bloque elegido. Actualizar desde main con árbol limpio; revisar PRs abiertos antes de editar.
2. **Primera entrega recomendada para Claude: PUR-070, ficha y plano del Dominio 1.** Usar plantilla y métricas de `docs/04_DOMINIOS_Y_NIVELES.md`; dejar ubicaciones de hub, cuatro salas, compuertas, spawns, rutas y frentes de Purga. Cerrar con plano revisable y siguiente bloque concreto; no construir toda la campaña.
3. Registrar aquí agente, rama, alcance y archivos antes de implementar. Esta recomendación no reserva una tarea ni afirma que Claude ya la leyó. **Al cerrar esta anotación no hay bloques reservados por Codex.**
4. Reutilizar Balance, InputFrame, HealthComponent, RoundManager/Progress/Score, portal y zona franca. No duplicar sistemas ni cambiar números de balance sin documentar motivo y evidencia.
5. Cada PR debe indicar qué criterios cumple y cuáles siguen pendientes, pruebas realmente ejecutadas y video si cambia jugabilidad. Mantener al día esta lista y el relevo. Para cambios solo documentales, revisar enlaces/contenido; no hace falta repetir la suite del juego.
6. Evitar tomar el mismo conjunto de archivos simultáneamente. Si se dividen tareas, dejar explícitos los contratos compartidos antes de modificar Runner, EventBus o el sandbox.

**Referencia de verificación:** [PR #12](https://github.com/Eltiokarma/Deathdrome-Concepto/pull/12) · [CI aprobada](https://github.com/Eltiokarma/Deathdrome-Concepto/actions/runs/42094925073). El roadmap conserva criterios de aceptación de diseño; sus casillas históricas sin marcar no deben interpretarse como inventario actualizado de código.

---

## 2026-11-05 · Codex · Purga radial de ensayo (PUR-034)

Rama `feat/PUR-034-purge` desde main tras PR #11 integrado. El ensayo F7 ya ejecuta una Purga letal al llegar a 0:00, con aviso rojo y sirena original generada en PCM al cruzar 0:30.

- Campo radial centrado en el portal `(0,0,15)`: radio inicial 56 m (cubre la arena de 60×60), hasta radio 7 m a 3.5 m/s; dominio 8 usa ×1.5. El último radio 7 m se cierra en 10 s, también en D8. Geometría exportada en la escena, velocidades/tiempos del balance existente.
- La región exterior del frente es letal a cualquier altura; incluye el centro exacto al cerrar. Ignora zona franca, escudo y coraza mediante DamageType.PURGE y conserva atribución de HealthComponent. No depende de solapamientos de Area3D ni permite saltar el frente.
- Runner ya admitido al portal queda fuera de la lista de blancos y puede completar su ascenso aunque cierre todo. El resto no reaparece: se deshabilita explícitamente PracticeRespawner y se bloquean R/F2 y recuperación por caída en PURGE/RESULTS.
- Muerte del jugador durante Purga termina el ensayo en RESULTS, con penalización/atribución ya procesadas y modelo retirado. Enter inicia otro ensayo; F7 sale. F8, solo como herramienta de prueba, adelanta primero al aviso de 30 s y luego a Purga sin modificar balance.
- CI añade purge.avi (18 s), adelantando solo el reloj del ensayo para mostrar frente y muerte. Ver resultados finales y revisión visual en el PR. Validación local inicial: 105 pruebas / 612 aserciones, lint y paquete aislado correctos.
- PUR-034 sigue parcial respecto al dominio definitivo: el greybox no tiene las cuatro salas/compuertas. Falta sustituir este frente radial por geometría de salas y validar su cobertura; no presentar este ensayo como diseño final. Pendientes libres: dominio/áreas, bots, piloto, arte y guardado de campaña.

Las entradas siguientes conservan el historial.

## 2026-11-05 · Codex · Puntaje de sesión en el ensayo de ronda

Rama `feat/round-score` desde main tras PR #10 integrado. RoundScore vive bajo RoundProgress y consume eventos de participantes registrados; el HUD de F7 escucha score_changed.

- Bajas: 1000; primera baja atribuida de cada ronda +300; weapon_id barrier/tower añade +250. Muerte sin atribución/suicidio resta 250. Mercy kill da +500 una vez por vida, sin afectar cuota; su emisor jugable/piloto sigue pendiente.
- Escape con cuota: +2000 y 10 por segundo completo del reloj capturado al entrar. Entrada exactamente con reloj 0 da +1000 de Purga. Terminar el ascenso durante Purga no concede ese bonus si se entró antes. El resultado del ensayo incluye el total ya actualizado.
- Se deduplican muertes por life_id, mercy kill por vida y escapes por ronda; no se puntúa en intro/cuenta/resultados. La primera sangre es compartida por todos los participantes y se reinicia entre rondas.
- Los puntos sobreviven muerte, reset de vehículo y nuevas rondas/dominios dentro de la misma sesión/instancia. Volver con F7 y recrear la escena inicia otra sesión. No hay guardado, récords, créditos ni campaña persistente: el futuro gestor debe conservar o persistir RoundScore y la identidad de sus participantes.
- Los bonus usan balance.json existente, sin cambiar valores. IDs de armas admitidos para bonus: barrier y tower. Fuentes externas no registradas se ignoran.
- Ver pruebas/CI y revisión de round.avi en el PR. Siguientes bloques: muros de Purga, bots y piloto; quedan libres al cerrar esta entrega.

Las entradas siguientes conservan el historial.

## 2026-11-05 · Codex · Barrera con reserva de segmentos (PUR-022)

Rama `feat/PUR-022-barrier` desde main después del PR #9. Mantener L / Ctrl / botón X del mando activa la estela; el HUD muestra energía. No se cambian consumo, regeneración, altura ni duración originales.

- BarrierWeapon consume InputFrame.barrier: energía por stats, 30/s, regeneración 10/s tras 1.5 s de soltar/bloquear. Mantener el botón con energía agotada no regenera. Activar rompe el escudo salvo dentro de zona franca.
- Reserva de 96 segmentos por Runner, creada en ready. Sin instanciar segmentos durante juego; saturación no sustituye segmentos vivos. Cada segmento vive 3.5 s, queda fijo en mundo y mide 1.2 m de alto en suelo plano. En pendientes la caja cubre el desnivel.
- Colisión sólida en layer barrier, con excepción para su dueño. Runner resuelve daño letal tras move_and_slide; consulta adicional detecta rivales ya superpuestos. Se puede saltar por encima del volumen y bloquea hitscan. La estela persiste al morir el dueño y conserva atribución hasta caducar; reset manual limpia su reserva.
- Zona franca bloquea emisión. Una intersección con su volumen disipa el segmento completo, aun si ambos extremos quedan fuera. Se usa envolvente conservadora en coordenadas de la zona: puede disipar antes en bordes diagonales, nunca conservar un segmento que la cruza.
- Parámetros técnicos añadidos al balance: ancho 0.12 m, intervalo nominal 0.05 s, reserva 96, salida trasera 1.2 m y corte de continuidad 6 m para teletransportes. Las pausas congelan vida y energía.
- CI agrega barrier.avi: emisor avanza con cámara mirando atrás; perseguidor cruza la estela. Validación local: suite previa de 85 pruebas correcta; las 11 pruebas finales de barrera (137 aserciones) pasan, además del lint. Importación y paquete aislado verificados. Resultado completo de CI y revisión visual en el PR. No se certifica rendimiento con ocho Runners en hardware real.
- Próximo: playtest de feel/barrera, muros de Purga, bots y puntaje (bonus de barrera aún no se concede: el sistema de score sigue pendiente). Se cierra la dependencia funcional de disipación de PUR-031; arte/efectos siguen siendo greybox. No hay tareas reservadas al finalizar.

Las entradas siguientes conservan el historial.

## 2026-11-05 · Codex · Zona franca espacial (PUR-031)

Rama `feat/PUR-031-safe-zone` desde main tras PR #8 integrado. Volumen cilíndrico visible alrededor del portal en F7; consulta geométrica inmediata al disparar/recibir daño, sin esperar señales de solapamiento de física.

- `SafeZone` sigue `round.hub_safe_mode`: always / round_start / off. round_start protege intro/cuenta y los primeros 10 s de PLAYING; el reloj del gestor conserva la pausa. Sin gestor, round_start permanece inactivo.
- `HealthComponent.in_safe_zone` combina la bandera manual existente con los volúmenes activos. Los volúmenes se consultan por posición actual: reset, teletransporte, salida y eliminación de una zona no dejan estados obsoletos. Solapamientos suman protección.
- El punto de referencia es el origen del Runner (centro de la huella), no el casco completo. Radio y altura usan coordenadas locales, admiten transformación del volumen. Valores por defecto: radio 20 m y altura 12 m; el sandbox usa radio 7 m para conservar el combate fuera del portal. No es el Área 0 completa del dominio final.
- Dentro no hay daño normal ni láser, hacia dentro o hacia fuera. Disparar estando bloqueado no rompe el escudo de aparición; salir restaura disparo. PURGE sigue siendo letal. HUD indica protección y excepción de Purga.
- PUR-031 queda pendiente de disipar segmentos de barrera, porque PUR-022 todavía no implementa esos segmentos. Las futuras armas deben respetar la misma propiedad de salud antes de disparar.
- Validación local: 76 pruebas / 417 aserciones, lint, importación y exportación/arranque PCK correctos. CI y revisión visual en el PR. Próximos bloques: barrera, muros de Purga, bots y pulido del portal. No hay tareas reservadas al finalizar.

Las entradas siguientes conservan el historial.

## 2026-11-04 · Codex · Portal selectivo y ascenso de ensayo (PUR-033)

Rama `feat/round-portal` desde main, después de PR #7 integrado. Portal en `(0, 0, 15)`, a la derecha del punto de inicio de F7; podio de Ø 10 m, anillo del color del jugador cuando cumple cuota.

- Cada Runner con cuota recibe una excepción de colisión propia; los demás siguen bloqueados. Solo PLAYING/PURGE y Runners vivos pueden entrar.
- Entrada real por Area3D: bloquea control, apaga láser y retira al Runner de los blancos. Ascenso de 3 s por túnel octogonal con cámara inferior y fundido; emite una sola vez `runner_escaped` con el reloj capturado al entrar.
- En este ensayo, la salida del jugador termina en RESULTS. Enter reinicia en la ronda siguiente; se restauran grupo, colisión y cámara, y se revocan los permisos antiguos. Esc pausa el ascenso; F7 vuelve a práctica. Durante ascenso se bloquean reset/selección/finalización manual.
- PURGE permite conducir hasta el portal, pero desactiva reaparición; todavía no hay muros de Purga. No confundir esto con una ronda completa/campaña.
- Parámetros: `portal.ascent_s=3` cumple diseño; `portal.ascent_height_m=12` es altura visual del prototipo. No cambia cuota, daño ni duración de ronda.
- CI graba 35 s: combate, cuota, conducción al portal y ascenso mediante InputFrame real. Resultados de pruebas y revisión visual en el PR.
- Pendientes para Opus: playtest/cámara y arte final del túnel; zona franca física, barrera, muros de Purga, bots y puntaje. El estado de acceso es por participante, la presentación usa un único observador local. No hay tareas reservadas al terminar.

Las entradas siguientes conservan el historial.

## 2026-11-04 · Codex · Cuotas conectadas a las bajas

PR #6 integrado en main tras CI correcta (merge `d93eec0`). Esta entrega parte de ese main en `feat/round-quota`.

- RoundProgress, hijo de RoundManager, registra participantes explícitos y consume `runner_destroyed`. Cuenta la atribución decidida por HealthComponent; no recalcula el atacante.
- Cada vida tiene un identificador creciente en HealthComponent; una muerte cuenta como máximo una vez, incluso si se repite la señal. Reset manual y respawn generan una nueva vida. No hay crédito retroactivo de muertes sin atribución.
- Bajas de PLAYING/PURGE suman; intro/cuenta/resultados, suicidio, mercy kill y participantes ajenos no suman. La muerte propia no borra la cuota; una nueva intro sí reinicia el progreso.
- F7 muestra bajas/cuota y CUOTA CUMPLIDA; `quota_reached` sale una vez al cruzar el umbral. El futuro portal puede consultar `has_quota(runner)`. Cumplir cuota no termina la ronda automáticamente.
- CI genera 30 s de combate en el ensayo de ronda para mostrar el progreso. Validación local: 64 pruebas; suite completa con 355 aserciones más una aserción de suicidio añadida y verificada en los 7 tests de cuotas (26 aserciones). Lint y paquete aislado correctos. CI final en el PR.
- Pendientes: portal sólido/selectivo y ascenso PUR-033, barrera PUR-022, zona franca física, muros de Purga y bots. No se implementa puntaje de campaña ni se declara cerrado PUR-033. Ninguna tarea reservada al finalizar.

Las entradas siguientes son históricas.

## 2026-11-04 · Codex · PUR-030: gestor de ronda y ensayo F7

Rama `feat/PUR-030-round-manager`, desde `main`. Implementado el ciclo LOADING → INTRO → COUNTDOWN → PLAYING → PURGE → RESULTS, reloj y fórmula de cuota. Ensayo F7 separado de la práctica. Validación local: 57 pruebas / 330 aserciones, lint, importación y PCK aislado correctos. CI y captura de 10 s de intro/cuenta/inicio en el PR.

- Intro de 4 s existente; se explicita una cuenta inicial de 3 s en `round.countdown_s`. Los 300 s de juego empiezan después. No cambian cuotas ni duración de juego.
- `begin(domain, round)` valida D1–8/R1–3; `finish(result)` es responsabilidad del nivel. No termina automáticamente por alcanzar cuota ni inventa duración de Purga.
- El ensayo bloquea conducción antes del inicio y después del reloj; Enter termina manualmente / inicia la siguiente ronda. F7 vuelve a práctica. No representa una campaña completa.
- Sin muros de Purga, portal, puntaje ni seguimiento de cuotas por jugador; cuota solo informativa. Respawn sigue siendo el de práctica y se desactiva al llegar a Purga.
- Siguiente bloque libre: PUR-022 barrera o integración de cuota/portal con RoundManager. Mantener el playtest físico pendiente. No hay tareas reservadas al finalizar esta entrega.

Las entradas siguientes conservan el historial.

## 2026-11-04 · Codex · Integración en main y video comprobado

**Estado vigente:** todo el prototipo quedó integrado en `main` mediante [PR #5](https://github.com/Eltiokarma/Deathdrome-Concepto/pull/5), merge `74037d0ed7890b1ce03ee805c32f48e8ddc8530b`. Incluye las entregas #1–#4 y práctica continua. Las instrucciones antiguas de integrar la cadena quedan reemplazadas por esta entrada. No hay tareas reservadas.

- [CI del código integrado](https://github.com/Eltiokarma/Deathdrome-Concepto/actions/runs/41934549623): correcta en datos, lint, importación Godot, GUT, exportación y arranque de PCK aislado. Validación local: **50 pruebas / 269 aserciones**.
- Video real de Godot de 15 segundos descargado y revisado: destrucción del blanco, cuenta atrás, reaparición con escudo y daño después de terminar la protección. Disponible en el artefacto `combat-prototype-preview` de esa ejecución.
- Para continuar: partir de `main` actualizado (`git switch main` y `git pull --ff-only` con árbol limpio); usar Godot **4.6.3**, preparar datos con `python3 scripts/prepare_data.py` y abrir `game/project.godot` / F5. Consultar README para instalación de GUT y comandos de validación; controles en `docs/11_CONDUCCION.md`.
- Para Opus/Claude: primero playtest de conducción/cámara y mando físico; después escoger un bloque acotado, barrera PUR-022 o RoundManager, y anotar la reserva antes de modificarlo.
- Límites: greybox, blanco estacionario y respawn de práctica; faltan bots, ronda, efectos finales y suspensión física completa. PracticeRespawner no sustituye el sistema de ronda. No se certifican rendimiento en GPU integrada ni mando físico mediante CI.

Las entradas siguientes son históricas; prevalece esta sección.

## 2026-11-04 · Codex · Práctica continua y robustez del daño

**Rama:** `feat/practice-respawn`, basada en PR #4. Conservar el orden de revisión e integración de los PR anteriores. No hay tareas reservadas al cerrar esta entrega.

- Nuevo PracticeRespawner exclusivo del sandbox: demora/escudo desde Balance, cuenta atrás, pausa, bloqueo por ocupación y cancelación al reiniciar manualmente. Emite `runner_respawned` una vez por ciclo. No implementa respawn de ronda/Purga.
- Salud rechaza datos de daño y tiempos no finitos. Estado de muerte fijado antes de llamar listeners de daño para evitar una segunda muerte reentrante.
- Pruebas de demora/escudo, pausa, punto ocupado, reset, entradas inválidas y callback de daño; ver PR para número final y CI. La captura de combate de CI ahora dura 15 s para mostrar destrucción, reaparición y escudo.
- La CI de PR #4 ya pasó; su video fue descargado y revisado (daño y baja visibles). Eso no sustituye revisar el video de esta rama.
- Instrucciones de uso/playtest y límites en docs/11_CONDUCCION.md. No cambian cifras de balance.
- Siguientes prioridades: revisar/integrar los PR, probar conducción/mando real, y después barrera (PUR-022) o RoundManager. No usar PracticeRespawner como sustituto del sistema de ronda.

Las entradas siguientes conservan el historial.

## 2026-11-04 · Codex · Salud y láser de ensayo

**Rama:** `feat/PUR-020-021-combat`, basada en PR #3. Continúa la cadena #1 → #2 → #3 → esta entrega; sin merges automáticos.

- HealthComponent es fuente de integridad: zona franca en ambos lados, escudo, coraza, multiplicadores direccionales/stat de armas, autodaño y excepciones letales. Atribuye al último atacante válido en 5 s mediante referencia débil; entorno/autotorre conservan la atribución vigente. Emite daño/destrucción en EventBus; no modifica puntaje/cuota.
- LaserWeapon: 8 Hz, cono ±15°, alcance 60 m, selección por menor ángulo, desempate por distancia, rayo de visión que respeta mundo/barreras, rampa sobre el mismo blanco y reinicio tras 0,4 s. Trazo y triángulo visuales de prototipo.
- Sandbox: blanco estacionario, integridad y contador de bajas de ensayo. Clic/J/RB dispara; R reinicia ambos. `--combat-preview` dispara InputFrame real para video de CI.
- Aclaradas en docs/02 dos reglas: barrera ignora escudo/coraza salvo zona franca; TTK continuo no equivale a instantes discretos de disparo. Roadmap ajusta únicamente la tolerancia del test discreto; números de balance intactos.
- Las protecciones están implementadas como estado del componente: todavía no hay pickups, volúmenes de zona franca, respawn de ronda ni StatusEffects. Purga/barrera solo tienen reglas de daño; sus emisores no existen aún.
- El contador de bajas del sandbox no es puntuación/campaña. El blanco desaparece al destruirse y se restaura manualmente; efectos de explosión/piloto quedan pendientes.
- Validación y video: ver discusión del PR. Revisión siguiente: integración de los PR, feel de conducción, y PUR-022 (barrera) o ronda/respawn. Ningún bloque queda reservado por Codex al terminar.

Las secciones siguientes son históricas.

## 2026-11-04 · Codex · Primer Runner manejable

**Rama:** `feat/PUR-003-014-driving`, basada en PR #2. PR apilado: revisar/integrar en orden #1 → #2 → esta entrega, retargeteando las bases después. No quedan bloques reservados por Codex al terminar.

### Implementado
- PUR-003: enums, DamageInfo y las señales tipadas de EventBus. Contratos; no daño ni ronda todavía.
- PUR-010: InputFrame saneado, PlayerInput, acciones de teclado/mando en project.godot. El Runner no lee Input directamente.
- PUR-011/012/013: CharacterBody3D con aceleración/freno, giro, agarre lateral, cuatro sondas de suelo, stats derivados y salto de 2,5 m con recarga. F2 selecciona cualquiera de los ocho; F3 muestra stats.
- PUR-014: cámara cercana/lejana/cabina, mirar atrás y SpringArm con barrido de esfera. Reinicio R y pausa Esc en el sandbox.
- Escena principal ahora `driving_sandbox.tscn`; la arena orbital original sigue intacta y accesible por F6.

### Límites y pruebas
- `docs/11_CONDUCCION.md` documenta controles, parámetros nuevos, pruebas y playtest pendiente.
- Las cuatro sondas inclinan la malla; no constituyen suspensión física del casco. PUR-011 queda como prototipo, pendiente de feel y suspensión completa.
- Las pruebas cubren movimiento y colisiones reales, salto, rampa/cornisa, cámara, InputMap, teclado + mando sintético y pausa. Ver discusión del PR para resultado final de CI y video.
- No afirmar soporte de mando físico o rendimiento en GPU integrada sin probar ese hardware.
- Las acciones de armas/radar están preparadas, pero no implementan combate/radar. Salud es solo el valor inicial de stats.
- Próximo bloque sugerido: revisión de conducción con Opus; luego PUR-020 (HealthComponent/daño) y PUR-021 (láser), o PUR-015 para retro-render.

Las entradas siguientes son históricas; prevalece esta sección.

## 2026-11-04 · Codex · Balance, pruebas y arena

**Rama:** `feat/PUR-002-005-foundations`, basada en `feat/PUR-001-godot-foundation` (PR #1). Entrega pendiente de revisión; integrar primero PR #1 o conservar su base al reorganizar los PR.

### Implementado
- **PUR-002:** autoload Balance y catálogo validado; getters tipados y stats de los ocho Runners, con instantáneas que no alteran el catálogo. Claves obligatorias/tipos en `game/core/balance_schema.json`; datos faltantes/malformados detienen el arranque con error explícito.
- **PUR-004:** GUT 9.6.1 fijado a commit, lint solo de nuestro código, CI con Godot 4.6.3 y prueba de PCK aislado. Badge de CI y comandos en README.
- **PUR-005:** escena greybox como escena principal, luz y cámara orbital de inspección; no es cámara de Runner. Dimensiones y pendientes verificadas por consultas físicas.
- JSON fuente en raíz; `prepare_data.py` genera las copias exportables. `lock_reference_weapons=3` hace explícita la referencia de la fórmula de fijación; no modifica los valores derivados.

### Verificación y pendientes
- GUT cubre tablas de los ocho Runners, getters, datos inválidos, aislamiento de las instantáneas, recarga fallida, geometría y colisiones.
- Apertura y ejecución headless, lint y paquete PCK aislado comprobados localmente. Resultado final de CI y vista de arena: ver discusión del PR.
- **PUR-005 no se declara cerrado:** falta medir >120 fps en una GPU integrada concreta y el playtest con el futuro Runner. No inferir rendimiento del render por software de CI.
- PUR-003 sigue pendiente. Definir contratos Runner/DamageInfo con gameplay antes de declarar señales tipadas que los referencien.
- Tras integrar: PUR-003 → PUR-010 → PUR-011 para llegar a conducción. Codex no reserva esos bloques.
- No se sembraron issues en masa. No hay armas, bots, ronda ni combate implementados.

Las secciones siguientes conservan el historial; prevalece la entrada más reciente.

## 2026-11-03 · Codex · PUR-001 listo para revisión

**Rama:** `feat/PUR-001-godot-foundation`. **Estado:** implementado y validado en headless; pendiente de revisión e integración. Este bloque no está disponible para otra implementación.

### Cambios
- Proyecto `game/project.godot` con Godot **4.6.3.stable** (edición estándar), renderer Compatibility y nueve capas de física según arquitectura §7.
- Carpetas de arquitectura §2 con `.gitkeep`; incluida `levels/_test/` para PUR-005.
- README con versión exacta y comando de apertura. El campo de features de Godot declara 4.6; la revisión 4.6.3 queda documentada, no bloqueada automáticamente.
- Exclusiones de exportaciones y builds dentro de `game/`.

### Verificación realizada
- `godot --version`: `4.6.3.stable.official.7d41c59c4`.
- `godot --headless --editor --path game --quit`: salida 0, sin errores.
- Comprobación temporal con ProjectSettings dentro del motor: coinciden los nueve nombres de capas y `gl_compatibility`, salida 0.
- `git check-ignore`: excluye `game/.godot/`, builds y exportaciones de raíz y de `game/`.
- No se ha probado la ventana gráfica, rendimiento GPU ni exportación. CI se revisará en el PR.

### Para Claude
- Revisar/integrar este PR antes de partir de PUR-001; quedan libres PUR-002, PUR-003 y PUR-005 tras integración. Ninguno está tomado por Codex.
- No se han creado escenas, autoloads vacíos ni gameplay. F5 todavía no tiene escena principal; PUR-005 aporta la arena.
- **Atención para PUR-002:** `data/` vive fuera de `game/` y por tanto fuera de `res://`. Resolver carga y empaquetado para las exportaciones manteniendo los JSON de raíz como fuente de verdad; no asumir que `res://data/` existe.
- Mantener las pruebas GUT/CI headless completas dentro de PUR-004.

Las entradas siguientes son históricas; el estado vigente es el de esta sección.

## 2026-11-03 · Codex · Importación inicial

**Estado:** preparación documental terminada; ningún bloque de implementación reservado por Codex.

### Hecho

- Importado el contenido de `purga-docs.zip` a la raíz del repositorio, sin la carpeta envolvente `purga/`.
- Corregida la URL de clonación y el directorio del README para `Eltiokarma/Deathdrome-Concepto`.
- Ejecutado `python3 scripts/validate_data.py`: pasa, 8 Runners y TTK de referencia de 4,67 s.
- Conservados los documentos de diseño y los datos de balance del ZIP.

### Siguiente bloque disponible

**PUR-001 — Crear proyecto Godot y estructura de carpetas.** Fijar primero una versión exacta de Godot; seguir `docs/07_ARQUITECTURA.md` y los criterios de `docs/08_ROADMAP.md`. Entregar por rama y PR. No considerar completado hasta comprobar apertura del proyecto y las nueve capas de física.

### Pendientes y límites de esta entrega

- No hay proyecto Godot ni pruebas de jugabilidad todavía.
- La comprobación local valida los datos existentes; no certifica toda la coherencia documental ni la robustez del validador frente a datos malformados.
- El workflow de CI se importa tal como viene; verificar su ejecución en GitHub antes de dar CI por confirmada.
- No se ha ejecutado `scripts/seed_github.sh`: no se han creado masivamente issues ni milestones.
- La configuración `.gdlintrc` mencionada en CONTRIBUTING aún no está incluida en el ZIP.

### Cómo relevamos tareas

1. Leer esta nota y la última versión de la rama principal antes de editar.
2. Anotar el bloque tomado, agente, rama y archivos previstos. Trabajar en un bloque pequeño por entrega.
3. Al terminar, dejar cambios, pruebas realmente ejecutadas, pendientes y commit o PR.
4. Si el otro agente ya tomó el mismo bloque, elegir otro o coordinar con Gerson antes de duplicar cambios.

Esta nota es el canal de relevo dentro del repositorio; no implica que el otro agente ya la haya leído.
