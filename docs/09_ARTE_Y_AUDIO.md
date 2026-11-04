# 09 · Arte y audio

## 1. Dirección

**Retro-futurismo carcelario de 1996, con identidad andina.** Polígonos duros, texturas pixeladas de baja resolución, colores saturados sobre fondos oscuros, luces de neón. Nada de realismo, nada de mapas normales, nada de posproceso caro.

Referencias de *sensación* (no de copia): arcades 3D de mediados de los 90, la arquitectura brutalista de penales, la geometría escalonada de las huacas, los colores de los tejidos del altiplano.

## 2. Reglas de legibilidad

1. **Fondo oscuro, actores brillantes.** Los Runners, pickups, torres y la Purga siempre más saturados y claros que el escenario.
2. **Un color = un significado.**

| Color | Significa | Nunca se usa para |
|---|---|---|
| Rojo con blanco | Peligro explosivo (torres) | Decoración |
| Amarillo y negro | Rampa / desnivel | Peligro de daño |
| Rojo pulsante | La Purga | Otra cosa |
| Color del Runner | Ese Runner y lo que emite | Escenario |
| Verde HUD | Información propia | Enemigos |

3. **Siluetas únicas** por Runner (prueba de escala de grises de [03 §3](03_RUNNERS.md#3-reglas-de-diseño-para-runners)).
4. **Cada sala tiene un motivo visual** (piso, luz o estructura) además de su número.

## 3. Presupuestos técnicos

| Asset | Triángulos | Textura | Notas |
|---|---|---|---|
| Runner | 600–1 200 | 256×256 | Contorno de color por shader o *inverted hull* |
| Piloto | ≤ 200 | 64×64 | — |
| Pickup | ≤ 150 | 64×64 | Gira y flota; emisivo |
| Torre de fusión | ≤ 100 | 64×64 | Emisivo cuando está cargada |
| Módulo de kit (4×4 m) | ≤ 300 | atlas 512×512 por Dominio | — |
| Sala completa | ≤ 25 k | — | — |
| Efectos | Sprites billboard animados de 64×64 o 128×128, 8–16 frames | — | Fuego, explosión, chispas, humo |

- Filtrado de texturas: *nearest* (pixelado).
- Iluminación: horneada (`LightmapGI`) + luces emisivas; máximo 4 luces dinámicas a la vez.
- Niebla de distancia por Dominio para ocultar el fin del dibujado y dar atmósfera.

## 4. Paletas por Dominio

| Dominio | Base | Acento | Piso |
|---|---|---|---|
| 1 Penal Altiplano | `#1B2838` | `#3DDC68` | Patrón tech azul |
| 2 Lago Negro | `#0A1A2A` | `#00E5FF` | Olas negras con reflejo cian |
| 3 Socavón | `#1A120A` | `#E0A030` | Roca y rieles |
| 4 Salar | `#E8E4DC` | `#FF5FA2` | Blanco cuarteado |
| 5 Fragua | `#140808` | `#FF4A1C` | Metal con ríos de magma |
| 6 Glaciar | `#0E2233` | `#B8F0FF` | Hielo translúcido |
| 7 Huaca | `#2A160C` | `#E8B04A` | Adobe con grecas |
| 8 La Purga | `#160A22` | `#FF2050` | Ajedrezado morado y blanco |

## 5. Audio

| Categoría | Lineamiento |
|---|---|
| Motores | Un loop por Runner con pitch según la velocidad; distintos por clase (ligero, medio, pesado) |
| Armas | Cada arma reconocible a ciegas; el láser sube de tono con la rampa |
| Avisos | Fijación (pitido acelerado), integridad baja, Purga, cuota cumplida: siempre audibles por encima de la música |
| Música | Electrónica rápida (breakbeat, techno, cumbia electrónica); temas propios con licencia clara |
| Música del jugador | Carpeta `user://music/` (homenaje a cuando el original tocaba el CD que pusieras) |
| Mezcla | Buses: Master → Música, SFX, Avisos, UI; los avisos ducken la música |

## 6. Licencias de assets

- Solo assets **originales del equipo** o con licencia **CC0 / CC-BY / OFL** compatible con distribución.
- Cada asset externo se registra en `game/assets/LICENSE-ASSETS.md`: archivo, autor, licencia, URL.
- **Prohibido:** extraer, trazar o "inspirarse de cerca" en modelos, texturas, sonidos o música del juego original o de cualquier otro juego.
