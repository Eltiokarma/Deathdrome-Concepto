# 04 · Dominios y niveles

## 1. Métricas (no negociables sin issue)

Basadas en las capturas del original y en el tamaño del Runner (1.0 m de ancho × 0.7 m de alto × 2.2 m de largo).

| Elemento | Medida | Razón |
|---|---|---|
| Ancho de pasillo | 7–9 m (≈ 7–9 Runners de ancho) | Espacio para esquivar, angosto para que el misil encuentre |
| Altura de techo | 4.5–6 m | Salto (2.5 m) + margen; techo siempre visible (sensación de túnel) |
| Sala de combate | 30–45 m de lado | ~1.5 s cruzarla a velocidad máxima |
| Área 0 (hub) | Ø 40 m | Ocho Runners en el anillo con espacio |
| Podio-portal | Ø 10 m, 1.5 m de alto | Visible desde las cuatro compuertas |
| Compuerta Área 0 ↔ sala | 8 m ancho × 5 m alto | — |
| Rampa | Pendiente ≤ 25°, franjas amarillo/negro | Legibilidad |
| Plataforma elevada | 2–4 m sobre el piso | Juego vertical |
| Línea recta más larga | ≤ 60 m (= alcance del láser) | Duelos a distancia posibles, no dominantes |
| Grid de construcción | 1 m; módulos de 4 m | Kits modulares reutilizables |

## 2. Estructura de un Dominio

```
                 ┌─────────────┐
                 │   ÁREA 1    │
                 │  (abre R1)  │
                 └──────┬──────┘
                        │ compuerta 1
  ┌─────────────┐  ┌────┴────┐  ┌─────────────┐
  │   ÁREA 4    ├──┤ ÁREA 0  ├──┤   ÁREA 2    │
  │  (abre R3)  │  │  hub +  │  │  (abre R1)  │
  └─────────────┘  │ portal  │  └─────────────┘
                   └────┬────┘
                        │ compuerta 3
                 ┌──────┴──────┐
                 │   ÁREA 3    │
                 │  (abre R2)  │
                 └─────────────┘
```

- Cada sala conecta con el Área 0 por **una compuerta principal**, rotulada sobre la puerta con **"SALIDA ↓ 0"** en el color del Dominio.
- Salas vecinas pueden conectarse entre sí por **pasajes secundarios** (más angostos, 6 m) solo si ambas están abiertas.
- Las compuertas de salas cerradas son sólidas y muestran una luz roja.
- **Rótulo de área:** cada sala muestra su número en grande (≥ 3 m de alto) en la entrada, visible desde el Área 0.

### Contenido mínimo por sala

| Elemento | Cantidad |
|---|---|
| Pickups de secundaria | 3–4 |
| Orbe de salud | 1 |
| Torres de fusión | 2–4 (cerca de cruces y rampas, nunca en la entrada) |
| Zonas de altura | ≥ 1 (rampa + plataforma) |
| Coberturas | Pilares o muros bajos cada 10–15 m |
| Puerta de llave | 0–1 (desde el Dominio 2), lleva a una zona con ítem raro |

### Área 0

- Sin pickups, sin torres, sin coberturas: es un escenario, no un campo de batalla.
- Anillo de aparición: 8 marcadores a 7 m del centro, mirando hacia afuera, uno por compuerta en pares.
- **Reloj diegético** gigante sobre cada compuerta, mostrando el mismo tiempo que el HUD.
- Volumen `SafeZone` (Area3D) que cubre todo el hub hasta la línea de compuertas.

## 3. Los ocho Dominios

Cada Dominio tiene una **paleta**, un **emblema** y un **modificador de juego** que lo distingue.

| # | Dominio | Concepto | Modificador | Paleta | Nuevo |
|---|---|---|---|---|---|
| 1 | **Penal Altiplano** | Prisión en la meseta, plataformas a varios niveles y lomas | Ninguno (tutorial implícito) | Azul acero + verde | Láser, barrera, misil, orbe, torres |
| 2 | **Lago Negro** | Penal semihundido; media sala con **olas sólidas** que suben y bajan | Superficie de olas: altera saltos y la línea de visión | Azul profundo + cian | Onda de choque, llaves |
| 3 | **Socavón** | Mina convertida en celdas; pozos y rampas verticales | Pasillos de 7 m (los más angostos); ascensores | Ocre + negro | Embestida |
| 4 | **Salar** | Penal sobre un salar blanco | Piso reflectante, poca cobertura, líneas largas | Blanco + rosa | Drenador |
| 5 | **Fragua** | Fundición a pie de volcán | Ríos de magma: 20 PI/s al contacto | Rojo + negro | Coraza |
| 6 | **Glaciar** | Penal tallado en hielo | Agarre lateral ×0.6 en zonas de hielo | Celeste + blanco | Látigo iónico |
| 7 | **Huaca** | Pirámide escalonada tecnificada | Mucha verticalidad, terrazas | Terracota + dorado | Camuflaje |
| 8 | **La Purga** | La sede del comité; arena final | La Purga avanza ×1.5; cuota máxima | Morado + rojo | Todo |

### Ficha de Dominio (plantilla)

Cada Dominio se documenta en `docs/dominios/NN_nombre.md` con esta plantilla antes de construirlo:

```markdown
# Dominio N · Nombre
## Concepto (2 líneas)
## Modificador
## Plano (imagen en docs/dominios/img/)
## Áreas
| Área | Tema | Ronda que abre | Pickups | Torres | Llave | Notas |
## Rutas principales (Área 0 → cada sala, tiempo a vel. 23.5 m/s)
## Puntos calientes esperados
## Riesgos (dónde se puede quedar atascado un bot o un jugador)
```

## 4. Proceso de construcción

1. **Plano en papel o en draw.io** con métricas → PR con la ficha.
2. **Blockout** con CSG/greybox en Godot (`game/scenes/levels/domain_NN/blockout.tscn`). Sin arte.
3. **Prueba de juego** con bots: ¿llegan a todas las salas? ¿hay puntos donde se atascan? ¿la Purga los alcanza de forma justa?
4. **Navegación** horneada (`NavigationRegion3D`) y validada.
5. **Pase de arte** con el kit modular del Dominio.
6. **Pase de iluminación** (luces horneadas donde se pueda; presupuesto en [09](09_ARTE_Y_AUDIO.md)).

## 5. Checklist de calidad de nivel

- [ ] Todas las métricas de la sección 1 respetadas.
- [ ] Ningún punto sin salida a menos de 20 m de una compuerta.
- [ ] Cada sala alcanzable desde el Área 0 en ≤ 6 s a velocidad media.
- [ ] Ninguna pared ni piso permite atravesarse (prueba de cornisas lentas, ver F5).
- [ ] Las torres no se pueden detonar desde el Área 0.
- [ ] La Purga cubre el 100 % del volumen jugable.
- [ ] Ningún rincón donde un bot quede atascado más de 2 s en 20 partidas de prueba.
- [ ] El número de área es legible desde el Área 0.
- [ ] 60 fps en GPU integrada objetivo con 8 Runners.
