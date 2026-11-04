# PURGA

[![CI](https://github.com/Eltiokarma/Deathdrome-Concepto/actions/workflows/ci.yml/badge.svg)](https://github.com/Eltiokarma/Deathdrome-Concepto/actions/workflows/ci.yml)

> Combate vehicular en arenas-prisión. Ocho convictos, motos armadas, una cuota de muertes y un reloj que, al llegar a cero, no termina la partida: **te persigue**.

**PURGA** (nombre de trabajo) es un juego de combate en arena en tercera persona, inspirado en el diseño de *DeathDrome* (Zipper Interactive, 1996). Es una obra **original**: reimplementamos ideas de diseño, no código, arte, nombres ni música del juego original. Ver [Reglas clean-room](CONTRIBUTING.md#reglas-clean-room).

- **Motor:** Godot **4.6.3.stable**, edición estándar (GDScript), renderer *Compatibility* para correr en GPUs integradas.
- **Plataforma objetivo:** PC (Windows / Linux). Multijugador LAN en una fase posterior.
- **Estado:** pre-producción. Prototipo de conducción: ocho Runners seleccionables, movimiento, salto y cámara. Láser y daño contra un blanco de ensayo; bots y ronda pendientes.

---

## El juego en 30 segundos

1. Ocho Runners amanecen en el **Área 0** (el hub central), una zona franca donde nadie puede disparar.
2. Suena la sirena y todos salen a las salas laterales (Áreas 1–4) a buscar armas.
3. Cada ronda exige una **cuota de kills** (empieza en 2 y sube).
4. Al cumplirla, el estado cambia a **ADVANCE**: vuelves al Área 0 y entras al **portal de escape**. La moto sube por un túnel vertical y escapas.
5. Si el reloj llega a 0 empieza la **Purga**: un muro de rayos que avanza desde los bordes hacia el centro y mata todo lo que toca.

## Documentación

| Doc | Para quién | Contenido |
|---|---|---|
| [00 · Investigación](docs/00_INVESTIGACION.md) | Todos | Qué sabemos del original, fuentes, incógnitas |
| [01 · GDD](docs/01_GDD.md) | Todos | Visión, loop, flujo de pantallas, decisiones de diseño, glosario |
| [02 · Combate y balance](docs/02_COMBATE_Y_BALANCE.md) | Gameplay | Todas las armas, daños, TTK, puntaje, reglas de daño |
| [03 · Runners](docs/03_RUNNERS.md) | Gameplay / Arte | Los 8 vehículos, stats y fórmulas |
| [04 · Dominios y niveles](docs/04_DOMINIOS_Y_NIVELES.md) | Level design | Métricas, estructura de áreas, los 8 Dominios |
| [05 · HUD y UI](docs/05_HUD_Y_UI.md) | UI | Cada elemento del HUD, menús, mensajes |
| [06 · IA](docs/06_IA.md) | Gameplay | Máquina de estados de los bots, dificultad |
| [07 · Arquitectura](docs/07_ARQUITECTURA.md) | Programación | Estructura Godot, autoloads, componentes, señales, capas |
| [08 · Roadmap](docs/08_ROADMAP.md) | Todos | Milestones e issues con criterios de aceptación |
| [09 · Arte y audio](docs/09_ARTE_Y_AUDIO.md) | Arte / Audio | Guía de estilo, paletas, presupuesto poligonal |

Los números de balance viven en [`data/balance.json`](data/balance.json) y [`data/runners.json`](data/runners.json). **Los docs explican; el JSON manda.** Si hay discrepancia, gana el JSON y se abre un issue para corregir el doc.

## Coordinación

Antes de comenzar una tarea, consultar [el relevo de trabajo](docs/10_RELEVO.md) y actualizar allí el bloque que se toma.

## Empezar a contribuir

```bash
git clone https://github.com/Eltiokarma/Deathdrome-Concepto.git
cd Deathdrome-Concepto
python3 scripts/prepare_data.py
godot --editor --path game
```

Usar Godot **4.6.3.stable**. F5 abre el banco de conducción. W/S aceleran/frenan, A/D giran, Espacio salta, C cambia cámara, V mira atrás, Esc pausa, F2 cambia Runner, F3 muestra stats y R reubica la moto. También hay mapeos de mando. Clic izquierdo, J o RB disparan el láser contra el blanco; R reinicia ambos. El blanco reaparece automáticamente tras 4 s con escudo de 3 s; espera si ocupas su punto de aparición. No hay armas secundarias ni bots.

Consulta [controles, pruebas y límites del prototipo](docs/11_CONDUCCION.md). La arena orbital anterior permanece en `game/levels/_test/test_arena.tscn` (F6).

### Datos y exportación

Editar únicamente `data/balance.json` y `data/runners.json` en la raíz. Ejecutar `python3 scripts/prepare_data.py` después de cada cambio: genera `game/data/`, ignorado por Git. El autoload `Balance` valida tipos y claves requeridas antes de publicar getters y stats; si no encuentra datos válidos, termina con código 1 y explica la ruta fallida.

El preset `game/export_presets.cfg` incluye esos JSON y el esquema. `python3 scripts/check_project.py` exporta un PCK y lo arranca desde una carpeta aislada para comprobar que no depende del árbol fuente. Un ejecutable Linux/Windows completo requiere las plantillas de exportación de Godot; esta comprobación solo genera el paquete PCK.

### Pruebas

```bash
python3 scripts/install_gut.py  # GUT 9.6.1, commit fijado; requiere git y red
python3 -m pip install gdtoolkit==4.5.0
python3 scripts/check_gdscript.py
python3 scripts/check_project.py
```

GUT se instala bajo `game/addons/gut/` (MIT, licencia incluida por el instalador). CI ejecuta validación de balance, lint, GUT, prueba del paquete aislado y publica un video de la arena en el artefacto `combat-prototype-preview`. Las pruebas geométricas verifican colisiones y medidas; no sustituyen el playtest de conducción ni la medición de 120 fps en GPU integrada.

1. Lee [CONTRIBUTING.md](CONTRIBUTING.md).
2. Elige un issue con la etiqueta `good first issue` del milestone activo ([Roadmap](docs/08_ROADMAP.md)).
3. Rama `feat/<id-issue>-descripcion`, PR contra `main`.

Para sembrar milestones, etiquetas e issues en un repo nuevo: `scripts/seed_github.sh` (requiere `gh` autenticado).

## Licencia

Código bajo [MIT](LICENSE). Los assets originales del proyecto (modelos, texturas, audio) se licencian aparte en `game/assets/LICENSE-ASSETS.md` cuando existan.

*DeathDrome* es marca y obra de sus respectivos titulares. Este proyecto no está afiliado ni respaldado por ellos.
