# Relevo de trabajo — Codex / Claude

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
