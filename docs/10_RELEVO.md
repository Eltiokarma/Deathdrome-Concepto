# Relevo de trabajo — Codex / Claude

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
