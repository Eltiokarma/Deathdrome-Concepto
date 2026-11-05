# 02 · Combate y balance

Todos los números de este documento están en [`data/balance.json`](../data/balance.json). **Si hay diferencia, manda el JSON.**

Unidades: metros (m), segundos (s), puntos de integridad (PI). Un Runner de blindaje medio tiene **100 PI**; el HUD muestra la integridad como % de su máximo.

---

## 1. Metas de diseño del balance

| Meta | Valor objetivo | Por qué |
|---|---|---|
| TTK solo con láser, por los costados, Runner medio | **4–5 s** | Suficiente para reaccionar y escapar; corto para que el láser sirva |
| TTK con láser de frente | **~6.5 s** | Encarar al rival es una defensa real |
| Kill con secundarias | **2–3 impactos** | Las secundarias deciden duelos, no los cierran solas |
| Muerte instantánea | Solo barrera, Purga y combo torre + otro daño | Lo instantáneo debe ser evitable y legible |
| Tiempo medio por kill del jugador | **40–70 s** en Dominio 1 | La cuota de 2 se cumple en ~2 min de 5 |

## 2. Reglas de daño

### 2.1 Orden de aplicación

Cada impacto produce un `DamageInfo { amount, type, source, direction, position }` y se procesa en este orden:

1. **Zona franca:** si el blanco o el atacante están en el Área 0 → daño = 0 (excepto tipo `PURGE`).
2. **Escudo de aparición** activo → daño = 0 (excepto `PURGE`).
3. **Coraza** activa → daño = 0 y sin efectos de estado (excepto `PURGE`).
4. **Multiplicador direccional** (solo tipo `LASER`): ver 2.2.
5. **Multiplicador del atacante** (stat de armas del Runner, solo `LASER`): ver [03](03_RUNNERS.md).
6. Restar de la integridad; si llega a 0 → destrucción.

**Precedencia de excepciones:** después de zona franca y autodaño, resolver los tipos letales antes del escudo/coraza. La regla letal siguiente prevalece sobre los pasos 2–3.

`PURGE` y `BARRIER` son daño **letal**: ignoran todo excepto la zona franca (la barrera no existe dentro del Área 0; la Purga sí entra).

### 2.2 Dirección (láser)

Ángulo entre la dirección del impacto y el frente del blanco:

| Zona | Ángulo | Multiplicador |
|---|---|---|
| Frente | ±45° | ×0.70 |
| Costados | 45°–135° | ×1.00 |
| Espalda | ±45° por detrás | ×1.20 |

### 2.3 Atribución de kills

- La kill es de quien hizo el **último daño en los últimos 5 s**.
- Torre de fusión: la kill es de quien la **detonó**; si se detonó sola (por contacto del propio muerto), del último atacante en 5 s; si no hay, nadie.
- Purga: del último atacante en 5 s; si no hay, nadie.
- Suicidio o muerte sin atribución: no suma ni resta kills; −250 puntos.
- **Solo las kills atribuidas suman a la cuota.**

### 2.4 Autodaño

- Tus propias armas no te dañan, **excepto** la embestida (5 PI al impactar).
- Las torres dañan a todos, incluido quien las detona.
- Tu barrera no te mata; la de otros sí.

## 3. Arma primaria: Láser

| Parámetro | Valor |
|---|---|
| Cadencia | 8 disparos/s (mantener botón) |
| Daño base | 1.5 PI por disparo → 12 DPS |
| Alcance | 60 m |
| Auto-apuntado | Cono de ±15° frente al Runner; elige el blanco más cercano al centro de la mira |
| Rampa | El multiplicador sube linealmente de ×1.0 a **×2.0** en 2 s de impacto continuo sobre el **mismo** blanco |
| Corte de rampa | Si pasan 0.4 s sin impactar a ese blanco, la rampa vuelve a ×1.0 |
| Munición | Infinita |
| Marcador | Triángulo sobre el blanco fijado, en el color del atacante |

**Daño acumulado** en impacto continuo, por los costados, multiplicador de armas 1.0:

- Durante la rampa (t ≤ 2 s): `D(t) = 12t + 3t²` → a los 2 s, 36 PI.
- Después: +24 PI/s.

### TTK solo láser (impacto continuo)

| Integridad del blanco | Costado | Espalda (×1.2) | Frente (×0.7) |
|---|---|---|---|
| 70 PI (blindaje 1) | 3.42 s | 2.93 s | 4.67 s |
| 85 PI (blindaje 2) | 4.04 s | 3.45 s | 5.56 s |
| **100 PI (blindaje 3)** | **4.67 s** | **3.97 s** | **6.45 s** |
| 115 PI (blindaje 4) | 5.29 s | 4.49 s | 7.35 s |
| 130 PI (blindaje 5) | 5.92 s | 5.01 s | 8.24 s |

Cálculo para el frente con 100 PI: hacen falta 100 / 0.7 = 142.9 PI "de costado" → 2 + (142.9 − 36) / 24 = 6.45 s.

### Discretización del prototipo (PUR-021)

La tabla anterior es continua. A 8 Hz, un impacto se resuelve cada 0,125 s; el primero ocurre tras un intervalo, no instantáneamente. Cada tiro integra la curva sobre su intervalo (multiplicador medio de la rampa), conservando exactamente el daño acumulado en los instantes de disparo. El tiempo real de destrucción se redondea al siguiente impacto: tolerancia de **un intervalo de tiro**, más el paso de física al observarlo. La curva continua conserva la comprobación numérica; exigir <2 % para todos los TTK discretos sería incompatible con esta cadencia. No se altera el DPS ni la tabla.

## 4. Arma primaria: Barrera

| Parámetro | Valor |
|---|---|
| Activación | Mantener botón; la moto deja una estela detrás |
| Energía máxima | 80 + 10 × stat de armas (110 con armas 3) |
| Consumo | 30 de energía/s |
| Duración con energía llena | ~3.7 s (armas 3) |
| Regeneración | 10/s, empieza 1.5 s después de soltar |
| Vida de cada segmento | 3.5 s |
| Altura del segmento | 1.2 m → **se puede saltar** (apogeo del salto 2.5 m) |
| Efecto | Muerte instantánea a cualquier Runner rival que la toque |
| Restricción | Deshabilitada en el Área 0; los segmentos que entren al Área 0 se disipan |
| Bonus | +250 puntos por kill con barrera |

Parámetros técnicos de la estela de prototipo: `segment_width_m=0.12`, `sample_interval_s=0.05`, `pool_size=96`, `rear_offset_m=1.2`, `max_gap_m=6`. La reserva no reemplaza segmentos vivos si se satura. La muestra conserva el resto temporal, con una emisión máxima por paso de física. El corte de continuidad evita unir teletransportes. En zona franca se disipa el segmento completo; en pendientes su caja cubre también el desnivel entre extremos.

## 5. Secundarias

Tres slots. Cada pickup llena un slot libre (se pueden repetir). Con los 3 llenos no recoges más. Ciclas con Q/E y disparas con el botón secundario.

| Arma | Dominio | Daño | Efecto | Detalle |
|---|---|---|---|---|
| **Misil rastreador** | 1 | 40 PI directo | — | Fijación de 0.6 s en cono de ±20° a ≤ 70 m. Sin fijación sale en línea recta. 32 m/s, giro 90°/s, vida 4 s. Al iniciar la fijación el blanco recibe el aviso **"TE TIENEN FIJADO"**. Se esquiva con giros cerrados o saltando en el último momento |
| **Onda de choque** | 2 | 50 PI en el centro → 15 PI en el borde | Detona torres en el radio | Radio 10 m, altura 1.6 m, requiere línea de visión, no te daña |
| **Embestida** | 3 | 60 PI + empuje | — | Fijación de 0.3 s a ≤ 25 m. Impulso de 1.0 s a ×2.2 de tu velocidad máxima, con dirección asistida. Si fallas, quedas lento 1.5 s. Te hace 5 PI |
| **Drenador** | 4 | 30 PI en 5 s (6 PI/s) | Vacía tu barrera y bloquea su regeneración 5 s | Proyectil de 40 m/s, alcance 50 m |
| **Látigo iónico** | 6 | 20 PI | Aturde 1.5 s: sin dirección ni disparo, conserva el impulso | Rayo instantáneo de 15 m. Tras un aturdimiento, el blanco es inmune al aturdimiento 3 s |

Combinaciones de referencia contra 100 PI:
- Misil + misil + ~1.5 s de láser.
- Embestida + misil.
- Látigo (aturdir) + láser por la espalda: 20 + ~3.3 s.
- Torre (70 en el centro) + misil.

## 6. Ítems (uso inmediato, no ocupan slot)

| Ítem | Dominio | Efecto | Reaparición |
|---|---|---|---|
| **Orbe de salud** | 1 | +35 PI (sin pasar el máximo) | 25 s |
| **Crédito de vida** | 1 | +1 crédito (máx. 9). Uno por Dominio, en zona de llave | No reaparece en la ronda |
| **Llave** (roja / verde / azul) | 2 | Abre las puertas de su color en esa ronda | No reaparece en la ronda |
| **Coraza** | 5 | Invulnerable 5 s, inmune a estados | 45 s |
| **Camuflaje** | 7 | Invisible 6 s (destello a < 10 m); nadie te puede fijar; se rompe al disparar | 45 s |

Los pickups de arma reaparecen a los **20 s** de ser recogidos.

## 7. Torre de fusión

| Parámetro | Valor |
|---|---|
| Estado | Cargada (brilla) o descargada (apagada) |
| Detonación | Cualquier impacto de láser, contacto de un Runner, onda de choque o misil |
| Daño | 70 PI en el centro → 25 PI en el borde |
| Radio | 8 m |
| Altura de la explosión | 1.6 m → saltar en el momento justo la evita |
| Línea de visión | Requerida (no atraviesa paredes) |
| Recarga | 25 s |
| Cadena | Una torre puede detonar otra dentro de su radio, con 0.15 s de retraso |
| Bonus | +250 puntos por kill con torre |

## 8. Movilidad relevante para el combate

| Parámetro | Valor |
|---|---|
| Salto | Apogeo 2.5 m, tiempo de vuelo ~1.4 s, recarga 1.2 s |
| Sin control aéreo | Solo una corrección del 20 % de la dirección en el aire |
| Choque contra pared | Sin daño; pierdes el 60 % de la velocidad |
| Choque Runner contra Runner | Sin daño (salvo embestida); rebote |

## 9. Muerte y reaparición

1. Integridad 0 → la moto explota y queda una **pira** 6 s.
2. El piloto se eyecta (pequeño, 10 PI, 6 m/s, sin armas) y tiene **2.5 s** para alejarse.
3. Si alguien lo mata: **mercy kill** (+500 puntos para el atacante, no suma a la cuota) y su reaparición tarda 2 s más.
4. Reaparición: **4 s** desde la muerte (6 s con mercy kill), en el Área 0, eyectado del portal.
5. **Escudo de aparición:** 3 s de invulnerabilidad; se cancela si disparas.
6. Reapareces con integridad completa, barrera llena y **slots vacíos**.

## 10. Ronda

| Parámetro | Valor |
|---|---|
| Duración | 5:00 |
| Cuota | `min(2 + floor((dominio − 1) / 2) + (ronda − 1), 7)` |
| Áreas abiertas | Ronda 1: 1–2 · Ronda 2: 1–3 · Ronda 3: 1–4 |
| Inicio | 4 s de intro + cuenta inicial de 3 s (`round.countdown_s`); las compuertas abren a los 0:00 de la cuenta inicial |

Cuota por Dominio y ronda:

| Dominio | R1 | R2 | R3 |
|---|---|---|---|
| 1–2 | 2 | 3 | 4 |
| 3–4 | 3 | 4 | 5 |
| 5–6 | 4 | 5 | 6 |
| 7–8 | 5 | 6 | 7 |

## 11. Purga

| Parámetro | Valor |
|---|---|
| Inicio | Reloj en 0:00 |
| Aviso | Sirena y timer en rojo desde 0:30 |
| Avance en salas | 3.5 m/s desde el perímetro hacia las compuertas del Área 0 (5.25 m/s en el Dominio 8) |
| Cierre del Área 0 | El anillo se cierra hacia el portal en 10 s |
| Efecto | Muerte instantánea, sin reaparición en la ronda |
| Bots | Huyen hacia el Área 0 en cuanto la Purga empieza |

## 12. Puntaje

| Evento | Puntos |
|---|---|
| Kill | 1000 |
| Primera sangre de la ronda | +300 |
| Kill con barrera | +250 |
| Kill con torre | +250 |
| Mercy kill | +500 |
| Ronda superada | +2000 |
| Tiempo restante al escapar | +10 por segundo |
| Escapar durante la Purga | +1000 |
| Suicidio / muerte sin atribución | −250 |

El puntaje se acumula entre rondas y Dominios. El bonus temporal cuenta segundos completos (`floor`) del reloj capturado al entrar al portal; no resta los 3 s de ascenso. El bonus de Purga corresponde a entrar con reloj exactamente 0, aunque el ascenso termine después de comenzar la Purga.

## 13. Cómo balancear

1. **Toca el JSON, no el código.** Todo valor de este doc es una clave de `balance.json`.
2. **Mide antes de opinar.** El modo debug (F3) muestra DPS, rampa del láser y TTK real por duelo; el log de partida (`user://logs/match_*.csv`) registra cada impacto.
3. **Un cambio por PR**, con etiqueta `balance` y el antes/después de las métricas del punto 1.
4. Si un valor del JSON cambia, actualiza la tabla correspondiente de este doc en el mismo PR.


### Parámetros del ascenso de prototipo

`portal.ascent_s = 3` conserva la duración del GDD. `portal.ascent_height_m = 12` define únicamente el recorrido visual de ensayo. El tiempo restante de salida se captura al entrar al portal, antes del ascenso.
