# Cómo contribuir a PURGA

Gracias por sumarte. Este documento explica cómo trabajamos para que cualquiera pueda agarrar un issue y avanzar sin pedir permiso.

## Reglas clean-room

PURGA está **inspirado** en el diseño de un juego de 1996, pero es una obra original. Para que siga siéndolo:

1. **No** subas, extraigas ni descompiles archivos del juego original (ejecutables, modelos, texturas, audio, mapas).
2. **No** uses los nombres originales de Runners, Dominios, personajes ni la marca.
3. **No** traces ni reproduzcas de cerca capturas del original para hacer arte. Las capturas sirven para entender *escala* y *legibilidad*, no como plantilla.
4. Mecánicas e ideas de diseño **sí** se pueden reinterpretar: eso es lo que documenta [docs/00](docs/00_INVESTIGACION.md).
5. Si dudas, abre un issue con la etiqueta `design-decision` antes de hacerlo.

## Flujo de trabajo

1. **Elige un issue** del milestone activo (ver [Roadmap](docs/08_ROADMAP.md)). Si es tu primera vez, busca `good first issue`.
2. **Coméntalo** ("lo tomo") para que nadie lo duplique. Si en 7 días no hay avance, se libera.
3. **Rama** desde `main`:
   - `feat/PUR-021-laser-rampa`
   - `fix/PUR-011-cornisa-atraviesa-pared`
   - `docs/...`, `balance/...`, `art/...`
4. **Commits** con [Conventional Commits](https://www.conventionalcommits.org/es/):
   - `feat(combat): rampa de daño del láser (PUR-021)`
   - `fix(motor): evitar atravesar cornisas lentas (PUR-011)`
   - `balance: misil 40 → 36 PI`
5. **Pull request** contra `main` usando la plantilla. Debe:
   - Referenciar el issue (`Closes #N`).
   - Marcar los criterios de aceptación del issue.
   - Incluir GIF o video corto si cambia algo visible o jugable.
   - Pasar CI.
6. **Revisión:** al menos una aprobación. Se hace *squash merge*.

## Estilo de código (GDScript)

- Tipado estático siempre: `var speed: float = 0.0`, `func apply(info: DamageInfo) -> void:`.
- `class_name` en `PascalCase`, archivos y variables en `snake_case`, constantes en `UPPER_SNAKE_CASE`.
- Código, nombres e identificadores en **inglés**; comentarios y docs en **español** (se aceptan en inglés).
- Un script por responsabilidad; preferir **componentes** (nodos hijos) a herencia profunda.
- **Ningún número mágico de gameplay en el código:** todo valor de balance sale de `Balance`.
- Señales globales solo en `EventBus`. El HUD **escucha**, nunca modifica estado.
- El Runner solo lee `InputFrame` (lo exige la IA y la futura red).
- `gdlint` sin errores (configuración en `.gdlintrc`).

## Balance

- Los números viven en `data/balance.json` y `data/runners.json`.
- Un cambio de balance = un PR con etiqueta `balance`, el motivo y las métricas antes/después.
- Si cambias un valor, actualiza la tabla del doc correspondiente en el mismo PR.
- `scripts/validate_data.py` corre en CI: comprueba JSON válido, claves requeridas y que los stats de cada Runner sumen 12.

## Tests

- Lógica pura (daño, fórmulas, cuota, atribución, contraseñas) **con tests GUT** en `game/tests/`.
- Física y feel: video en el PR y, si aplica, una escena de prueba reproducible.

## Assets

- Solo originales o con licencia CC0 / CC-BY / OFL; registro en `game/assets/LICENSE-ASSETS.md`.
- Respeta los presupuestos de [docs/09](docs/09_ARTE_Y_AUDIO.md).
- Archivos fuente pesados (`.blend`, `.kra`, `.psd`) van en `art_source/` con Git LFS (se configura en M7).

## Reportar bugs

Usa la plantilla de bug: pasos para reproducir, esperado vs. obtenido, versión del commit, sistema y GPU, y si puedes, el log `user://logs/`.

## Conducta

Trato respetuoso, crítica a las ideas y no a las personas. Las discusiones de diseño se resuelven con argumentos, prototipos o datos de playtest.
