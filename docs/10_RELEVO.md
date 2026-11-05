# Relevo de trabajo — Codex / Claude

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
