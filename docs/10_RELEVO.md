# Relevo de trabajo — Codex / Claude

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
