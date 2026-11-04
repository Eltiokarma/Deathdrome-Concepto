# 03 · Runners

Ocho motos de combate. Todas tienen **láser y barrera**; se diferencian en cuatro stats de 1 a 5 que **suman 12** en todos los Runners. Así ninguno es estrictamente mejor que otro.

Datos en [`data/runners.json`](../data/runners.json). Nombres en quechua: identidad propia y sin relación con el original.

## 1. Stats y fórmulas

Corrige el fallo F3 del original (velocidad y armas no se notaban): cada punto cambia algo que **se siente**.

| Stat | Afecta | Fórmula | 1 | 3 | 5 |
|---|---|---|---|---|---|
| **Velocidad** (S) | Velocidad máxima | `16 + 2.5·S` m/s | 18.5 | 23.5 | 28.5 |
|  | Aceleración (0 → máx.) | `2.6 − 0.2·S` s | 2.4 | 2.0 | 1.6 |
| **Blindaje** (B) | Integridad máxima | `55 + 15·B` PI | 70 | 100 | 130 |
|  | Masa (empuje recibido) | `0.8 + 0.1·B` | 0.9 | 1.1 | 1.3 |
| **Manejo** (M) | Giro | `70 + 20·M` °/s | 90 | 130 | 170 |
|  | Agarre lateral | `0.70 + 0.06·M` | 0.76 | 0.88 | 1.00 |
| **Armas** (A) | Multiplicador del láser | `0.85 + 0.05·A` | ×0.90 | ×1.00 | ×1.10 |
|  | Energía de barrera | `80 + 10·A` | 90 | 110 | 130 |
|  | Fijación de misil | `0.6 − 0.05·(A − 3)` s | 0.70 | 0.60 | 0.50 |

La referencia de armas 3 para fijación vive en `weapons.missile.lock_reference_weapons`; el tiempo base y la variación por punto permanecen en `data/balance.json`. No cambia ningún valor de la tabla.

## 2. Los ocho

| Runner | Significado | Vel. | Blind. | Manejo | Armas | Rol | Silueta | Color |
|---|---|---|---|---|---|---|---|---|
| **Puma** | puma | 4 | 2 | 4 | 2 | Cazador ágil: entra, golpea, sale | Baja y alargada, morro en cuña | Naranja `#FF8A1F` |
| **Kuntur** | cóndor | 5 | 2 | 3 | 2 | El más rápido; vive de la embestida y la huida | Alas laterales, perfil plano | Blanco `#E8EEF2` |
| **Chikchi** | granizo | 2 | 4 | 2 | 4 | Artillero: aguanta y castiga | Bloque angular con torreta alta | Celeste `#5EC8FF` |
| **Lloqlla** | huaico | 2 | 5 | 2 | 3 | Tanque: el más resistente | Ancha y pesada, placas frontales | Marrón `#A0673A` |
| **Illapa** | rayo | 3 | 2 | 3 | 4 | Daño puro, frágil | Delgada, aleta vertical | Amarillo `#FFE135` |
| **Wik'uña** | vicuña | 3 | 3 | 5 | 1 | El mejor manejo; esquiva misiles | Fina, ruedas expuestas | Verde `#3DDC68` |
| **Supay** | demonio andino | 4 | 3 | 2 | 3 | Agresivo, difícil de controlar | Cuernos frontales, morro largo | Rojo `#FF3B3B` |
| **Amaru** | serpiente sagrada | 3 | 3 | 3 | 3 | Equilibrado; el de inicio | Curvas suaves, segmentada | Magenta `#E040FB` |

Comprobación: todas las filas suman 12.

### Valores derivados

| Runner | Vel. máx. | Integridad | Giro | Láser | Barrera | TTK láser recibido (costado) |
|---|---|---|---|---|---|---|
| Puma | 26.0 m/s | 85 | 150°/s | ×0.95 | 100 | 4.04 s |
| Kuntur | 28.5 | 85 | 130 | ×0.95 | 100 | 4.04 s |
| Chikchi | 21.0 | 115 | 110 | ×1.05 | 120 | 5.29 s |
| Lloqlla | 21.0 | 130 | 110 | ×1.00 | 110 | 5.92 s |
| Illapa | 23.5 | 85 | 130 | ×1.05 | 120 | 4.04 s |
| Wik'uña | 23.5 | 100 | 170 | ×0.90 | 90 | 4.67 s |
| Supay | 26.0 | 100 | 110 | ×1.00 | 110 | 4.67 s |
| Amaru | 23.5 | 100 | 130 | ×1.00 | 110 | 4.67 s |

TTK medido con un atacante de armas 3 (×1.00).

## 3. Reglas de diseño para Runners

1. **Silueta primero.** A 40 m y a 640×360 tienen que distinguirse sin color. Prueba: render en escala de grises a 64×36 px; si dos se confunden, se rediseña.
2. **Color único y saturado** por Runner. Ese color se usa en: contorno del modelo, estela de barrera, marcador de fijación, HUD del jugador y nombre en el kill feed.
3. **Presupuesto:** 600–1 200 triángulos, una textura de 256×256, sin mapas normales (estética retro).
4. **Puntos de anclaje** en el modelo: `Muzzle` (láser), `RearEmitter` (barrera), `SecondaryMount`, `PilotEject`, `CameraTarget`.
5. **Pilotos**: nombres de convicto generados por partida (lista en `data/convicts.json`, a crear en M5), mostrados en el kill feed como `NOMBRE (RUNNER)`.

## 4. Desbloqueo

- Inicio: Amaru, Puma, Chikchi, Wik'uña.
- Dominio 2 completado: Lloqlla.
- Dominio 4: Kuntur.
- Dominio 6: Illapa.
- Dominio 8: Supay.
