# 08 · Roadmap

Cada milestone termina en algo **jugable y demostrable**. Los issues tienen ID `PUR-NNN`; `scripts/seed_github.sh` lee este archivo y los crea en GitHub (cada `### PUR-...` es un issue y cada `## M...` un milestone).

**Formato de cada issue:** título, etiquetas, dependencias, descripción y criterios de aceptación. Un issue está **terminado** cuando todos sus criterios están marcados en el PR que lo cierra.

Etiquetas: `infra`, `gameplay`, `combat`, `ai`, `ui`, `level`, `art`, `audio`, `network`, `balance`, `docs`, `research`, `good first issue`, `design-decision`.

---

## M0 · Fundaciones

Objetivo: proyecto que abre, carga datos y pasa CI.

### PUR-001 · Crear proyecto Godot y estructura de carpetas
**Etiquetas:** `infra`, `good first issue`  
**Depende de:** —

Crear `game/project.godot` con renderer `gl_compatibility`, la estructura de [07 §2](07_ARQUITECTURA.md#2-estructura-del-repositorio) con `.gitkeep` donde haga falta, y las capas de colisión con nombre de [07 §7](07_ARQUITECTURA.md#7-capas-de-colisión).

**Criterios de aceptación**
- [ ] El proyecto abre sin errores en la versión de Godot fijada en el README.
- [ ] Las 9 capas de física tienen nombre.
- [ ] `.gitignore` excluye `.godot/` y exportaciones.

### PUR-002 · Autoload Balance
**Etiquetas:** `infra`  
**Depende de:** PUR-001

Autoload que lee `data/balance.json` y `data/runners.json`, valida que existan todas las claves requeridas y expone getters tipados y los valores derivados de los Runners.

**Criterios de aceptación**
- [ ] `Balance.get_f("weapons.laser.damage_per_shot")` devuelve 1.5.
- [ ] `Balance.runner("amaru").max_integrity` devuelve 100.
- [ ] Una clave faltante produce un error claro al arrancar, con la ruta de la clave.
- [ ] Tests GUT para las fórmulas de stats de los 8 Runners contra la tabla de [03](03_RUNNERS.md).

### PUR-003 · EventBus y enums
**Etiquetas:** `infra`, `good first issue`  
**Depende de:** PUR-001

Implementar `event_bus.gd` con las señales de [07 §3](07_ARQUITECTURA.md#señales-de-eventbus) y `enums.gd` con `DamageType`, `AreaId` y estados de ronda.

**Criterios de aceptación**
- [ ] Todas las señales declaradas con tipos.
- [ ] Ningún script fuera de `autoload/` declara señales globales.

### PUR-004 · Integración continua
**Etiquetas:** `infra`  
**Depende de:** PUR-001

Workflow de GitHub Actions que valide los JSON (`scripts/validate_data.py`), corra `gdlint` y los tests GUT en modo headless.

**Criterios de aceptación**
- [ ] El workflow corre en cada PR y en `main`.
- [ ] Un JSON inválido o una suma de stats ≠ 12 rompe el build.
- [ ] Badge de estado en el README.

### PUR-005 · Escena de prueba greybox
**Etiquetas:** `level`, `good first issue`  
**Depende de:** PUR-001

`game/levels/_test/test_arena.tscn`: piso de 60×60 m, rampas de 15° y 25°, plataforma de 3 m, pasillo de 7 m, muro bajo, techo a 5 m en una zona.

**Criterios de aceptación**
- [ ] Métricas según [04 §1](04_DOMINIOS_Y_NIVELES.md#1-métricas-no-negociables-sin-issue).
- [ ] Luz y entorno simples; corre a > 120 fps en GPU integrada.

---

## M1 · Manejo y cámara

Objetivo: manejar un Runner y que se sienta bien.

### PUR-010 · InputFrame y PlayerInput
**Etiquetas:** `gameplay`, `good first issue`  
**Depende de:** PUR-003

Clase `InputFrame` y nodo `PlayerInput` que la llena desde teclado y mando con el mapeo de [05 §6](05_HUD_Y_UI.md#6-controles-por-defecto).

**Criterios de aceptación**
- [ ] Teclado y mando funcionan a la vez sin conflicto.
- [ ] Acciones registradas en el `InputMap` del proyecto con los nombres del doc.

### PUR-011 · RunnerMotor arcade
**Etiquetas:** `gameplay`  
**Depende de:** PUR-010, PUR-005

Movimiento con `CharacterBody3D`: suspensión de 4 rayos, alineación a la normal del piso, aceleración, frenado, giro y agarre lateral, choque con pared (−60 % de velocidad).

**Criterios de aceptación**
- [ ] Sube rampas de 25° sin perder el contacto.
- [ ] No atraviesa paredes ni pisos al bajar despacio por una cornisa (prueba del fallo F5).
- [ ] Todos los valores salen de `Balance`.
- [ ] Video corto en el PR.

### PUR-012 · Stats de Runner aplicados
**Etiquetas:** `gameplay`  
**Depende de:** PUR-002, PUR-011

`Runner.setup(id)` aplica velocidad, aceleración, giro, agarre e integridad derivados.

**Criterios de aceptación**
- [ ] Cambiar de Kuntur a Lloqlla se nota claramente en velocidad y giro.
- [ ] Panel de debug (F3) muestra los valores derivados.

### PUR-013 · Salto
**Etiquetas:** `gameplay`, `good first issue`  
**Depende de:** PUR-011

**Criterios de aceptación**
- [ ] Apogeo de 2.5 m ± 0.1, recarga de 1.2 s, control aéreo del 20 %.

### PUR-014 · Cámara de persecución
**Etiquetas:** `gameplay`  
**Depende de:** PUR-011

Tres modos (cercana, lejana, cabina) con `SpringArm3D`, retraso suave de giro y mirar atrás.

**Criterios de aceptación**
- [ ] Modo cercano: offset (0, 1.4, 3.6) m, inclinación −7°, FOV vertical 60°.
- [ ] Nunca atraviesa paredes.
- [ ] La cámara no contiene lógica de juego.

### PUR-015 · Render retro
**Etiquetas:** `art`, `good first issue`  
**Depende de:** PUR-001

`SubViewport` a 640×360 escalado con filtro *nearest*; opción para render nativo.

**Criterios de aceptación**
- [ ] Escalado entero sin bordes borrosos a 1280×720 y 1920×1080.
- [ ] Opción conmutable en tiempo de ejecución.

---

## M2 · Combate base

Objetivo: dos Runners se pueden destruir con láser y barrera.

### PUR-020 · HealthComponent y DamageInfo
**Etiquetas:** `combat`  
**Depende de:** PUR-002, PUR-003

Implementar el orden de aplicación de daño de [02 §2.1](02_COMBATE_Y_BALANCE.md#21-orden-de-aplicación), la atribución de kills (último atacante en 5 s) y las señales de daño y destrucción.

**Criterios de aceptación**
- [ ] Tests GUT para cada paso del orden (zona franca, escudo de aparición, coraza, dirección, stat).
- [ ] Tests de atribución: torre, entorno, suicidio.
- [ ] `PURGE` mata incluso con coraza; nada daña dentro del Área 0 salvo `PURGE`.

### PUR-021 · Láser con auto-apuntado y rampa
**Etiquetas:** `combat`  
**Depende de:** PUR-020, PUR-012

**Criterios de aceptación**
- [ ] Cono de ±15°, alcance 60 m, 8 disparos/s, 1.5 PI base.
- [ ] Rampa ×1.0 → ×2.0 en 2 s; se reinicia a los 0.4 s sin impacto.
- [ ] Multiplicadores direccionales ×0.7 / ×1.0 / ×1.2.
- [ ] Test de la curva continua de [02 §3](02_COMBATE_Y_BALANCE.md#ttk-solo-láser-impacto-continuo) con error < 2 %; el TTK observado a 8 Hz admite un intervalo de tiro más un paso de física (ver discretización en 02).

### PUR-022 · Barrera
**Etiquetas:** `combat`  
**Depende de:** PUR-020, PUR-011

**Criterios de aceptación**
- [ ] Energía, consumo y regeneración según `balance.json`.
- [ ] Segmentos de 1.2 m de alto que duran 3.5 s, en pool (sin instanciar en caliente).
- [ ] Letal para rivales, inofensiva para el dueño; se puede saltar.
- [ ] No se activa dentro del Área 0.

### PUR-023 · Muerte, pira y piloto
**Etiquetas:** `combat`, `art`  
**Depende de:** PUR-020

**Criterios de aceptación**
- [ ] Explosión + pira de fuego (sprite billboard animado) durante 6 s.
- [ ] Piloto eyectado de 10 PI que se mueve 2.5 s; matarlo emite `mercy_kill`.

### PUR-024 · Reaparición y escudo de aparición
**Etiquetas:** `combat`  
**Depende de:** PUR-023

**Criterios de aceptación**
- [ ] Reaparece en el Área 0 a los 4 s (6 s tras mercy kill).
- [ ] Escudo de 3 s que se cancela al disparar.
- [ ] Integridad y barrera llenas, slots vacíos.

### PUR-025 · HUD mínimo
**Etiquetas:** `ui`, `good first issue`  
**Depende de:** PUR-020

Integridad, barrera, marcador de fijación del láser. Solo escucha señales.

**Criterios de aceptación**
- [ ] Ningún script del HUD modifica estado de juego.

---

## M3 · La ronda

Objetivo: una ronda completa de principio a fin en la arena de prueba.

### PUR-030 · RoundManager
**Etiquetas:** `gameplay`  
**Depende de:** PUR-020

Estados `LOADING → INTRO → COUNTDOWN → PLAYING → PURGE → RESULTS`, reloj de 5:00, cuota por fórmula.

**Criterios de aceptación**
- [ ] Test de la fórmula de cuota contra la tabla de [02 §10](02_COMBATE_Y_BALANCE.md#10-ronda).
- [ ] Mensaje de intro con cuota.

### PUR-031 · Zona franca (Área 0)
**Etiquetas:** `gameplay`, `design-decision`  
**Depende de:** PUR-030

Implementa D-01. Soporta `hub_safe_mode`: `always` (por defecto), `round_start` y `off`.

**Criterios de aceptación**
- [ ] En modo `always`, ningún arma dispara dentro y nadie recibe daño dentro (salvo la Purga).
- [ ] Los segmentos de barrera que entran se disipan.

### PUR-032 · AreaTracker
**Etiquetas:** `gameplay`, `good first issue`  
**Depende de:** PUR-030

**Criterios de aceptación**
- [ ] `area_changed` se emite una sola vez al cruzar cada umbral, sin parpadeos en el borde.

### PUR-033 · Portal y ascenso
**Etiquetas:** `gameplay`, `art`  
**Depende de:** PUR-030

Implementa D-07: se abre solo para quien cumplió la cuota, iluminado en su color. Secuencia de ascenso por túnel vertical de 3 s.

**Criterios de aceptación**
- [ ] Para quien no cumplió, el portal es sólido.
- [ ] Al entrar: cámara de ascenso, fundido, `runner_escaped` con el tiempo restante.

### PUR-034 · La Purga
**Etiquetas:** `gameplay`  
**Depende de:** PUR-030

**Criterios de aceptación**
- [ ] Avance de 3.5 m/s desde los perímetros; cierre del Área 0 en 10 s.
- [ ] Mata sin reaparición; cubre el 100 % del volumen jugable.
- [ ] Aviso a 0:30 (sirena, reloj rojo).

### PUR-035 · Puntaje y atribución
**Etiquetas:** `gameplay`  
**Depende de:** PUR-020, PUR-030

**Criterios de aceptación**
- [ ] Todos los eventos de [02 §12](02_COMBATE_Y_BALANCE.md#12-puntaje) suman o restan lo indicado.
- [ ] Solo las kills atribuidas cuentan para la cuota.

### PUR-036 · Compuertas por ronda
**Etiquetas:** `level`, `good first issue`  
**Depende de:** PUR-030

**Criterios de aceptación**
- [ ] R1 abre áreas 1–2, R2 suma la 3, R3 suma la 4; las cerradas tienen luz roja.

---

## M4 · Armas, ítems y peligros

Objetivo: el arsenal completo funcionando en la arena de prueba.

### PUR-040 · Inventario y pickups
**Etiquetas:** `combat`  
**Depende de:** PUR-020

**Criterios de aceptación**
- [ ] 3 slots, repetibles, ciclado con Q/E; con los slots llenos no se recoge.
- [ ] Pickups flotando y girando; reaparecen a los 20 s.

### PUR-041 · Sistema de fijación
**Etiquetas:** `combat`  
**Depende de:** PUR-040

**Criterios de aceptación**
- [ ] Fijación por cono, distancia y línea de visión; emite `lock_started` / `lock_lost`.
- [ ] El camuflaje impide la fijación.

### PUR-042 · Misil rastreador
**Etiquetas:** `combat`  
**Depende de:** PUR-041

**Criterios de aceptación**
- [ ] Valores de [02 §5](02_COMBATE_Y_BALANCE.md#5-secundarias); sin fijación sale recto.
- [ ] Se puede esquivar con un giro cerrado a velocidad media (prueba con 10 intentos: ≥ 5 esquivas).

### PUR-043 · Onda de choque
**Etiquetas:** `combat`  
**Depende de:** PUR-040

**Criterios de aceptación**
- [ ] `ShapeCast3D` cilíndrico (r 10 m, h 1.6 m) con comprobación de línea de visión (D-06).
- [ ] Atenuación lineal 50 → 15 PI; detona torres.

### PUR-044 · Torre de fusión
**Etiquetas:** `combat`, `level`  
**Depende de:** PUR-043

**Criterios de aceptación**
- [ ] Estados cargada / descargada visibles; recarga de 25 s.
- [ ] Detonación por láser, contacto, onda o misil; cadenas con 0.15 s de retraso.
- [ ] **El truco del salto funciona:** saltando en el momento justo no recibes daño.

### PUR-045 · Embestida
**Etiquetas:** `combat`  
**Depende de:** PUR-041

**Criterios de aceptación**
- [ ] 60 PI + empuje proporcional a la masa; 5 PI al atacante; penalización de 1.5 s al fallar.

### PUR-046 · Drenador
**Etiquetas:** `combat`  
**Depende de:** PUR-040

**Criterios de aceptación**
- [ ] 6 PI/s durante 5 s; vacía y bloquea la barrera del blanco.

### PUR-047 · Látigo iónico
**Etiquetas:** `combat`  
**Depende de:** PUR-040

**Criterios de aceptación**
- [ ] Rayo de 15 m, 20 PI, aturdimiento de 1.5 s, inmunidad de 3 s.

### PUR-048 · Ítems
**Etiquetas:** `combat`, `good first issue`  
**Depende de:** PUR-040

Orbe de salud, coraza, camuflaje, llaves y crédito de vida.

**Criterios de aceptación**
- [ ] Valores y reapariciones de [02 §6](02_COMBATE_Y_BALANCE.md#6-ítems-uso-inmediato-no-ocupan-slot).

---

## M5 · Inteligencia artificial

Objetivo: siete bots que completan rondas de forma creíble.

### PUR-050 · Percepción
**Etiquetas:** `ai`  
**Depende de:** PUR-021

**Criterios de aceptación**
- [ ] Cono ±70°, 60 m, línea de visión; oído a 25 m; memoria de 4 s.

### PUR-051 · BotBrain y estados base
**Etiquetas:** `ai`  
**Depende de:** PUR-050, PUR-040

`SALIR_HUB`, `BUSCAR_ARMAS`, `COMBATIR`, `CAZAR`.

**Criterios de aceptación**
- [ ] El bot solo produce `InputFrame`.
- [ ] Reparto de salas al salir del hub (≤ 3 bots por sala).

### PUR-052 · Estados de supervivencia y objetivo
**Etiquetas:** `ai`  
**Depende de:** PUR-051, PUR-033, PUR-034

`ESQUIVAR`, `RETIRADA`, `ESCAPAR`, `HUIR_PURGA`.

**Criterios de aceptación**
- [ ] En 20 rondas de prueba, los bots que cumplen cuota escapan en ≥ 90 % de los casos.

### PUR-053 · Tácticas
**Etiquetas:** `ai`  
**Depende de:** PUR-052, PUR-044

**Criterios de aceptación**
- [ ] Las 6 tácticas de [06 §2](06_IA.md#tácticas-dentro-de-combatir), cada una activable por dificultad.

### PUR-054 · Perfiles de dificultad
**Etiquetas:** `ai`, `balance`  
**Depende de:** PUR-053

**Criterios de aceptación**
- [ ] Perfiles 1–5 desde `balance.json`; reglas anti-frustración de [06 §4](06_IA.md#4-reglas-anti-frustración).

### PUR-055 · Depuración de IA
**Etiquetas:** `ai`, `good first issue`  
**Depende de:** PUR-051

**Criterios de aceptación**
- [ ] F4 muestra estado, ruta y cono; log CSV de transiciones.

---

## M6 · HUD, menús y campaña

Objetivo: el juego completo envuelto en su interfaz.

### PUR-060 · HUD completo
**Etiquetas:** `ui`  
**Depende de:** PUR-025, PUR-040

**Criterios de aceptación**
- [ ] Todos los elementos de [05 §3](05_HUD_Y_UI.md#3-elementos), teñidos con el color del Runner.

### PUR-061 · Kill feed y mensajes
**Etiquetas:** `ui`, `good first issue`  
**Depende de:** PUR-060

**Criterios de aceptación**
- [ ] Mensajes de [05 §3](05_HUD_Y_UI.md#mensajes-centrales) con sus colores y duraciones.

### PUR-062 · Radar
**Etiquetas:** `ui`  
**Depende de:** PUR-060

**Criterios de aceptación**
- [ ] Rotado con el jugador, 60 m, marcadores de borde, pickups, portal y frente de la Purga.

### PUR-063 · Menú principal y opciones de partida
**Etiquetas:** `ui`  
**Depende de:** PUR-002

**Criterios de aceptación**
- [ ] Flujo de [01 §3.3](01_GDD.md#33-flujo-de-pantallas) navegable con teclado, mando y ratón.
- [ ] Vista 3D del Runner girando con barras de stats.

### PUR-064 · Pausa, fin de ronda y fin de Dominio
**Etiquetas:** `ui`  
**Depende de:** PUR-063, PUR-035

**Criterios de aceptación**
- [ ] Resumen con desglose de puntos; contraseña al terminar un Dominio.

### PUR-065 · Guardado, contraseñas y créditos
**Etiquetas:** `gameplay`  
**Depende de:** PUR-064

**Criterios de aceptación**
- [ ] `user://save.json` con esquema versionado.
- [ ] Contraseña válida restaura Dominio y créditos; inválida muestra error.
- [ ] Fallar ronda cuesta 1 crédito; 0 créditos = Game Over.

### PUR-066 · Accesibilidad y traducción
**Etiquetas:** `ui`  
**Depende de:** PUR-060

**Criterios de aceptación**
- [ ] Opciones de [05 §5](05_HUD_Y_UI.md#5-accesibilidad-desde-m6); textos en `.csv` de traducción (ES base, EN segundo).

---

## M7 · Vertical slice: Dominio 1 (Penal Altiplano)

Objetivo: **una demo pública** de un Dominio completo con arte, audio y bots.

### PUR-070 · Ficha y plano del Dominio 1
**Etiquetas:** `level`, `docs`  
**Depende de:** —

**Criterios de aceptación**
- [ ] `docs/dominios/01_penal_altiplano.md` con la plantilla de [04 §3](04_DOMINIOS_Y_NIVELES.md#ficha-de-dominio-plantilla) y plano.

### PUR-071 · Blockout y navegación del Dominio 1
**Etiquetas:** `level`  
**Depende de:** PUR-070, PUR-036

**Criterios de aceptación**
- [ ] Checklist de [04 §5](04_DOMINIOS_Y_NIVELES.md#5-checklist-de-calidad-de-nivel) completo.

### PUR-072 · Kit modular y arte del Dominio 1
**Etiquetas:** `art`, `level`  
**Depende de:** PUR-071

**Criterios de aceptación**
- [ ] Assets originales con licencia registrada en `LICENSE-ASSETS.md`; presupuesto de [09](09_ARTE_Y_AUDIO.md).

### PUR-073 · Audio base
**Etiquetas:** `audio`  
**Depende de:** PUR-042

**Criterios de aceptación**
- [ ] SFX de motor, láser, barrera, misil, explosión, aviso de fijación, sirena, Purga, ascenso.
- [ ] Carpeta `user://music/` para la música del jugador (OGG/MP3), además de la propia.

### PUR-074 · Benchmark y optimización
**Etiquetas:** `infra`  
**Depende de:** PUR-072, PUR-054

**Criterios de aceptación**
- [ ] `bench_domain01.tscn`: ≥ 60 fps medios y ≥ 45 mínimos en GPU integrada objetivo con 8 Runners.

### PUR-075 · Playtest y primer pase de balance
**Etiquetas:** `balance`  
**Depende de:** PUR-074

**Criterios de aceptación**
- [ ] ≥ 5 testers, ≥ 20 rondas registradas; métricas de [02 §1](02_COMBATE_Y_BALANCE.md#1-metas-de-diseño-del-balance) medidas y ajustadas.
- [ ] Informe en `docs/playtests/2027-xx-xx.md`.

---

## M8 · Multijugador LAN

### PUR-080 · Servidor autoritativo
**Etiquetas:** `network`  
**Depende de:** PUR-075

**Criterios de aceptación**
- [ ] Clientes envían `InputFrame`, servidor simula y difunde a 30 Hz; predicción local e interpolación de 100 ms.

### PUR-081 · Lobby LAN
**Etiquetas:** `network`, `ui`  
**Depende de:** PUR-080

**Criterios de aceptación**
- [ ] Descubrimiento por broadcast en LAN, elección de Runner, listo/no listo, hasta 8 jugadores.

### PUR-082 · Combate sincronizado
**Etiquetas:** `network`, `combat`  
**Depende de:** PUR-080

**Criterios de aceptación**
- [ ] Daño, fijaciones, barrera y torres consistentes con 100 ms de latencia simulada.

### PUR-083 · Modo cuota en LAN
**Etiquetas:** `network`, `gameplay`  
**Depende de:** PUR-082

**Criterios de aceptación**
- [ ] Ronda completa con portal y Purga para 2–8 jugadores humanos, con bots de relleno.

---

## M9 · Campaña completa

### PUR-090 · Dominio 2 · Lago Negro (olas sólidas)
**Etiquetas:** `level`  
**Depende de:** PUR-075

**Criterios de aceptación**
- [ ] Superficie de olas jugable sin atascos; checklist de nivel completo.

### PUR-091 · Dominio 3 · Socavón
**Etiquetas:** `level`  
**Depende de:** PUR-090

**Criterios de aceptación**
- [ ] Ascensores y pozos; checklist de nivel completo.

### PUR-092 · Dominio 4 · Salar
**Etiquetas:** `level`  
**Depende de:** PUR-091

**Criterios de aceptación**
- [ ] Piso reflectante dentro del presupuesto; checklist completo.

### PUR-093 · Dominio 5 · Fragua
**Etiquetas:** `level`  
**Depende de:** PUR-092

**Criterios de aceptación**
- [ ] Magma de 20 PI/s; los bots lo evitan; checklist completo.

### PUR-094 · Dominio 6 · Glaciar
**Etiquetas:** `level`  
**Depende de:** PUR-093

**Criterios de aceptación**
- [ ] Zonas de hielo con agarre ×0.6; checklist completo.

### PUR-095 · Dominio 7 · Huaca
**Etiquetas:** `level`  
**Depende de:** PUR-094

**Criterios de aceptación**
- [ ] Terrazas verticales navegables por bots; checklist completo.

### PUR-096 · Dominio 8 · La Purga
**Etiquetas:** `level`  
**Depende de:** PUR-095

**Criterios de aceptación**
- [ ] Purga ×1.5, cuota máxima, cierre de campaña con créditos finales.
