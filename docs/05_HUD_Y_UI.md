# 05 · HUD y UI

## 1. Principios

1. **El HUD informa amenazas antes que estadísticas.** Lo que te puede matar va en rojo y en el centro de la pantalla.
2. **Teñido del Runner.** Barras, marcos y marcador de fijación usan el color del Runner del jugador.
3. **Marco delgado.** El original usaba un marco metálico que comía ~25 % de la pantalla. Nosotros: barras superior e inferior de ≤ 12 % de alto cada una, en 16:9.
4. **Escalado entero.** Todo el HUD se dibuja a 640×360 y se escala ×2/×3/×4 con filtro *nearest* para nitidez.

## 2. Distribución

```
┌──────────────────────────────────────────────────────────────────────┐
│ [LLAVES ●●●]   [ 4:56.8 ]   [ FALTAN 2 KILLS ]      [ 12 580 ] [3K] │  ← barra superior
│                                                                      │
│                ZURDO MATÓ A CHASKI CON MISIL                         │  ← kill feed (centro alto)
│                                                                      │
│                     ▼ (marcador sobre blanco)                        │
│                                                                      │
│                    ⚠ TE TIENEN FIJADO ⚠                              │  ← avisos críticos
│                                                                      │
│                         [ Runner ]                                   │
│ [≡][◯][◯][◯]  [▬▬▬▬ barrera ▬▬▬]  [ 84 % ]  [ÁREA 2]  [radar ▢]     │  ← barra inferior
│ [◆◆◆◇◇◇◇◇◇ créditos]               [ALERTA]                          │
└──────────────────────────────────────────────────────────────────────┘
```

## 3. Elementos

### Barra superior

| Elemento | Contenido | Comportamiento |
|---|---|---|
| **Llaves** | 3 casillas: roja, verde, azul | Se encienden al recogerlas; se vacían al terminar la ronda |
| **Reloj** | `M:SS.d` | Blanco; amarillo desde 1:00; rojo parpadeante desde 0:30; en la Purga muestra `PURGA` |
| **Estado** | `FALTAN N KILLS` / `AVANZA` | `AVANZA` en el color del Runner y con flecha al portal |
| **Puntaje** | Acumulado | Animación de conteo al sumar |
| **Kills** | `N K` en la ronda | — |

### Barra inferior

| Elemento | Contenido | Comportamiento |
|---|---|---|
| **Primaria** | Ícono del láser y estado de rampa (3 rayas que se llenan) | La rampa muestra el multiplicador ×1.0 → ×2.0 |
| **Slots secundarios** | 3 círculos con el ícono del arma | El seleccionado tiene marco brillante; vacío = círculo oscuro |
| **Barrera** | Barra horizontal en color del Runner | Parpadea al estar bloqueada por el drenador |
| **Integridad** | `NN %` | Verde > 60 %, amarillo 30–60 %, rojo < 30 %; sacudida al recibir daño |
| **ALERTA** | Etiqueta roja | Visible si: te fijaron un misil, integridad < 25 % o la Purga está a < 15 m |
| **Área** | `ÁREA N` | Cambia al cruzar un umbral de área |
| **Radar** | Cuadrado de 64×64 px, 60 m de alcance, rotado con el jugador | Enemigos como puntos de su color; fuera de rango, triángulos en el borde; pickups como cruces pequeñas; portal abierto en tu color; frente de la Purga como borde rojo |
| **Créditos** | Hasta 9 rombos | — |

### En el mundo (3D, sobre la escena)

| Elemento | Detalle |
|---|---|
| **Marcador de fijación** | Triángulo invertido sobre el blanco del láser, en tu color; se llena según la rampa |
| **Fijación de misil** | Cuadro que se cierra sobre el blanco durante los 0.6 s |
| **Indicador fuera de pantalla** | Flecha en el borde hacia el portal (solo en estado `AVANZA`) |
| **Nombres** | Sobre cada Runner a < 25 m, en su color |
| **Reloj diegético** | Sobre las compuertas del Área 0 |

### Mensajes centrales

| Mensaje | Color | Duración |
|---|---|---|
| `RONDA N — X KILLS PARA ESCAPAR` | Blanco | 4 s (intro) |
| `¡VAMOS!` | Color del Runner | 1 s |
| `X MATÓ A Y CON ARMA` | Color del atacante | 3 s, máx. 3 líneas en pila |
| `MISIL RECOGIDO` (y demás) | Blanco | 1.5 s |
| `TE TIENEN FIJADO` | Rojo parpadeante | Mientras dure la fijación |
| `CUOTA CUMPLIDA — VUELVE AL ÁREA 0` | Color del Runner | 3 s |
| `PURGA` | Rojo | 3 s al empezar |
| `MERCY KILL +500` | Dorado | 1.5 s |

## 4. Menús

Todos los menús son navegables con teclado, mando y ratón. Fuente pixel monoespaciada de licencia libre (por ejemplo, de la familia OFL).

| Pantalla | Contenido |
|---|---|
| **Título** | Logo de PURGA, "PRESIONA CUALQUIER TECLA" |
| **Menú principal** | Empezar · Opciones · Controles · Guía de entrenamiento · Récords · Créditos · Salir |
| **Opciones de partida** | ¡VAMOS! · casillas de contraseña · Runner (vista 3D girando + stats en barras) · Dominio (emblema + nombre; bloqueados con candado) |
| **Guía de entrenamiento** | Una página por arma e ítem: ícono, video corto en bucle, números clave |
| **Fin de ronda** | Kills, tiempo restante, desglose de puntos, botón continuar |
| **Fin de Dominio** | Contraseña del siguiente Dominio |
| **Pausa** | Continuar · Reiniciar ronda · Opciones · Salir al menú |

## 5. Accesibilidad (desde M6)

- Escala del HUD 75–150 %.
- Modo daltónico: los colores de Runner se acompañan de un **patrón** (rayas, puntos, cuadros) en el contorno y en el radar.
- Opción para desactivar el parpadeo.
- Subtítulos para los avisos de audio.
- Remapeo total de controles.

## 6. Controles por defecto

| Acción | Teclado | Mando |
|---|---|---|
| Acelerar / frenar | W / S | RT / LT |
| Girar | A / D | Stick izquierdo |
| Saltar | Espacio | A |
| Láser | Clic izq. / J | RB |
| Secundaria | Clic der. / K | LB |
| Ciclar secundaria | Q / E | D-pad ← / → |
| Barrera | Ctrl / L | X |
| Cámara (cercana / lejana / cabina) | C | D-pad ↑ |
| Mirar atrás | V | Stick derecho clic |
| Radar ampliado | Tab | Back |
| Pausa | Esc | Start |
