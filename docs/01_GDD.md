# 01 · Game Design Document

**Proyecto:** PURGA (nombre de trabajo)  
**Versión del doc:** 0.1 · noviembre 2026  
**Dueño:** @Eltiokarma

---

## 1. Visión

Un shooter vehicular de arena **corto, tenso y legible**. Cada ronda dura como máximo 5 minutos y tiene un objetivo claro (la cuota), un enemigo común (el reloj y la Purga) y siete rivales que quieren lo mismo que tú.

**Pilares** (toda decisión se mide contra estos tres):

1. **Cazar o ser cazado.** Siempre sabes quién está cerca, quién te fijó y quién mató a quién. La información es parte del combate.
2. **El reloj es un depredador.** Al llegar a cero, la Purga no termina la partida: te persigue hacia el centro. La tensión crece hasta el último segundo.
3. **Trucos que se aprenden.** Saltar sobre una explosión, encerrar a alguien con tu barrera, detonar una torre a distancia. Un jugador experto se ve distinto a uno nuevo.

**Anti-pilares** (lo que *no* es):
- No es un simulador: física arcade, sin daño por caída, sin combustible.
- No es un battle royale: arenas cerradas, partidas cortas, reaparición.
- No es grind: no hay mejoras permanentes que compren victorias.

## 2. Ficha

| | |
|---|---|
| Género | Combate vehicular en arena, tercera persona |
| Jugadores | 1 + 7 bots (campaña) · hasta 8 en LAN (fase posterior) |
| Duración de ronda | ≤ 5:00 + Purga (~25 s) |
| Duración de campaña | 8 Dominios × 3 rondas ≈ 2–3 h |
| Motor | Godot 4.x, GDScript, renderer Compatibility |
| Resolución interna | 640×360 escalada (modo retro) o nativa (opción) |
| Mínimo objetivo | GPU integrada Intel Iris / UHD, 60 fps |

## 3. Loop de juego

### 3.1 Loop de ronda

```
[Intro de ronda]  "RONDA 1 — 2 KILLS PARA ESCAPAR"   (4 s, cámara orbita el hub)
        │
[Área 0: Zona franca]  Todos en el anillo del portal. Nadie puede disparar.
        │  sirena → compuertas abiertas
[Caza]  Salas 1–4: pickups, kills, torres de fusión
        │
        ├─ cuota cumplida → estado ADVANCE → portal se abre para ti
        │        └─ volver al Área 0 → entrar al portal → [Ascenso] → puntos por tiempo
        │
        └─ reloj = 0 → [PURGA] muro de rayos avanza hacia el centro
                 ├─ cumples cuota y llegas al portal → escapas
                 └─ te alcanza → mueres sin reaparición → ronda fallida (−1 crédito)
```

### 3.2 Loop de campaña

```
Menú → Elegir Runner → Elegir Dominio (desbloqueados) → Ronda 1 → 2 → 3 → Dominio completo
     → contraseña + guardado automático → siguiente Dominio
```

Créditos de vida: empiezas con 3. Morir no cuesta créditos (reapareces); **fallar una ronda** (no escapar antes de que la Purga cierre) cuesta 1 crédito y reinicia la ronda. Con 0 créditos: Game Over → vuelves al inicio del Dominio actual.

> **Por qué no cuesta morir:** en el original morir te sacaba de la acción y la cuota era el verdadero objetivo. Cobrar por morir castiga al jugador agresivo, que es el que queremos. El costo de morir es **tiempo** (reaparición + volver a armarte).

### 3.3 Flujo de pantallas

```
Arranque → Título → Menú principal
   ├─ Empezar  → Opciones de partida (Runner / Dominio / Contraseña / ¡VAMOS!) → Partida
   ├─ Opciones (video, audio, controles, accesibilidad)
   ├─ Controles
   ├─ Guía de entrenamiento (manual in-game con armas e ítems)
   ├─ Récords
   ├─ Créditos
   └─ Salir
Partida → Pausa (continuar / reiniciar ronda / opciones / salir)
       → Fin de ronda (resumen: kills, tiempo, puntos) → siguiente ronda
       → Fin de Dominio (contraseña) → Opciones de partida
       → Game Over → Récords
```

## 4. El Área 0 y el portal

Es la pieza central de cada Dominio y la que más define el juego.

- **Forma:** sala circular, Ø 120 m. En el centro, el **podio-portal** (Ø 10 m) con un anillo luminoso suspendido encima.
- **Inicio de ronda:** los 8 Runners aparecen en el anillo exterior del podio, mirando hacia las 4 compuertas.
- **Zona franca:** dentro del Área 0 **no se puede infligir daño de ningún tipo** (armas deshabilitadas, barrera apagada, torres ausentes). Ver D-01.
- **Portal cerrado:** el podio es un bloque sólido con la señalización de salida apagada.
- **Portal abierto (para ti):** al cumplir la cuota, el podio se ilumina **en tu color**. Solo tú puedes entrar; para el resto sigue sólido.
- **Ascenso:** al entrar, el control pasa a una secuencia de 3 s: la moto acelera por un túnel octogonal **vertical**, la cámara la sigue desde abajo y la pantalla funde a blanco. Es la recompensa visual de la ronda.
- **Reaparición:** quien muere reaparece eyectado desde el podio (no desde las salas), con escudo de aparición. Como el Área 0 es zona franca, no hay *spawn camping* posible.

## 5. La Purga

- Empieza cuando el reloj llega a 0:00.
- Muros de rayos aparecen en el perímetro de cada sala y avanzan hacia las compuertas del Área 0 a 10 m/s.
- Contacto = muerte inmediata, **sin reaparición** en lo que queda de ronda.
- Al llegar a las compuertas, la Purga entra al Área 0 y se cierra como un anillo hacia el portal en 10 s. **La zona franca no protege de la Purga.**
- Si cumples la cuota durante la Purga, el portal se abre y aún puedes escapar.
- Señales: sirena distinta, el timer parpadea en rojo desde 0:30, el radar muestra el frente de la Purga como un borde rojo.

Valores en [02 · Combate y balance](02_COMBATE_Y_BALANCE.md#purga).

## 6. Decisiones de diseño

Registro de decisiones. Para cambiar una, abrir un issue con etiqueta `design-decision`.

| ID | Decisión | Por qué | Alternativa descartada |
|---|---|---|---|
| **D-01** | El Área 0 es **zona franca permanente**: nadie inflige daño dentro. | Elimina el spawn camping del original (F1) y respeta el recuerdo de que al inicio no se podía dañar. El tiempo sigue corriendo: esconderse no da nada. | Zona franca solo los primeros 10 s (configurable en `balance.json` como `hub_safe_mode: "round_start"`). |
| **D-02** | Reaparición en el Área 0, con 3 s de escudo que se cancela al disparar. | Coherente con D-01; el escudo evita emboscadas en las compuertas. | Puntos de reaparición en las salas. |
| **D-03** | Morir no cuesta créditos; fallar la ronda sí. | Premia la agresividad; el castigo real es el tiempo. | Créditos por muerte (original probable). |
| **D-04** | La barrera mata al instante, pero dura poco (~3 s de energía) y se puede saltar. | Es el arma con más carácter; el salto le da contrajuego. | Daño fijo de 80. |
| **D-05** | El láser hace +20 % por la espalda y −30 % de frente. | Premia el posicionamiento (en el original, de frente se aguantaba más). | Daño uniforme. |
| **D-06** | Las explosiones (torres, onda de choque, misiles) tienen **altura limitada** y requieren **línea de visión**. | Hace funcionar el truco de saltar la explosión y corrige el bug de la pared (F5). | Esferas de daño. |
| **D-07** | El portal se abre solo para quien cumplió la cuota. | Evita que otros escapen "de arrastre" y crea un objetivo personal. | Portal abierto para todos al cumplir alguien. |
| **D-08** | Armas desbloqueadas por Dominio. | Corrige F2: siempre hay algo nuevo. | Todo disponible desde el inicio. |
| **D-09** | Nombres, Runners, Dominios y arte **propios**. | Legalidad y identidad. | Usar nombres del original. |

## 7. Progresión de contenido

| Dominio | Nuevo |
|---|---|
| 1 | Láser, barrera, misil, orbe de salud, torres de fusión |
| 2 | Onda de choque, llaves de color |
| 3 | Embestida nitro |
| 4 | Drenador |
| 5 | Escudo nano |
| 6 | Espada iónica |
| 7 | Camuflaje |
| 8 | Todos; la Purga avanza 50 % más rápido |

## 8. Modos

- **Campaña** (MVP): 8 Dominios × 3 rondas contra bots.
- **Arena libre**: cualquier Dominio desbloqueado, reglas configurables (cuota, tiempo, bots, armas).
- **LAN** (M8): deathmatch por cuota hasta 8 jugadores; luego modos por equipos.

## 9. Glosario

| Término | Significado |
|---|---|
| **Runner** | La moto del jugador o de un bot. |
| **Dominio** | Una arena-prisión completa (Área 0 + 4 salas). |
| **Área** | Zona numerada de un Dominio. Área 0 = hub. |
| **Cuota** | Kills necesarios para escapar en la ronda. |
| **ADVANCE** | Estado tras cumplir la cuota: dirígete al portal. |
| **Portal** | Podio central del Área 0, salida de la ronda. |
| **Ascenso** | Secuencia de escape por el túnel vertical. |
| **Purga** | Muro de rayos que barre la arena cuando el reloj llega a 0. |
| **Zona franca** | Área sin daño (el Área 0). |
| **Integridad** | Vida del Runner, en % en el HUD. |
| **Mercy kill** | Matar al piloto eyectado. |
| **Torre** | Torre de fusión: peligro explosivo del escenario. |
| **TTK** | *Time to kill*: tiempo para destruir un Runner. |
