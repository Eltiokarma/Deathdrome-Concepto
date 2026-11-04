# 00 · Investigación del juego original

Este documento resume lo que se sabe de *DeathDrome* (1996) a partir de reseñas, wikis, códigos de trucos y capturas de pantalla. Sirve como **referencia de diseño**, no como especificación: lo que construimos está en el [GDD](01_GDD.md).

> **Regla:** nada de este doc autoriza copiar assets, textos, nombres de Runners/Dominios ni código del original. Ver [clean-room](../CONTRIBUTING.md#reglas-clean-room).

## Ficha

| Campo | Dato |
|---|---|
| Desarrollador | Zipper Interactive (su primer juego; luego hicieron SOCOM, Crimson Skies, MechWarrior 3) |
| Editor | Viacom New Media |
| Lanzamiento | Fines de 1996, Windows 95 |
| Género | Combate vehicular en arena, tercera persona |
| Resolución | 320x200 hasta 640x480 |
| Multijugador | LAN (IPX/TCP), luego online por la red HEAT de SegaSoft |
| Hito técnico | Promocionado como el primer juego compatible con Intel MMX |
| Motor | Propio, no documentado públicamente |

## Lo confirmado

### Premisa
Año 2057, cárceles sobrepobladas. Un comité gubernamental convierte las ejecuciones en espectáculo: convictos en motos armadas pelean en "super-prisiones"; quien cumple su cuota de muertes, avanza; al final, la libertad.

### Estructura
- **8 Runners** (motos futuristas) con 4 stats: velocidad, blindaje, armas, manejo.
- **8 Dominios** (arenas), **3 rondas** cada uno.
- Cada Dominio: **hub central + 4 áreas**. Ronda 1 abre áreas 1–2; ronda 2 abre la 3; ronda 3 abre la 4.
- El HUD numera la zona actual: **hub = AREA 0**, salas = 1–4. Las salas tienen su número rotulado en grande en la entrada.
- Progreso por **contraseñas** por Dominio (no había guardado).

### Loop de ronda
1. Intro: "ROUND N — X KILLS REQUIRED TO ESCAPE".
2. Todos arrancan en el podio central, mirando hacia afuera.
3. Corren a las salas por armas y kills.
4. Cuota cumplida → estado **ADVANCE** → volver al hub → entrar al centro del podio (EXIT).
5. Secuencia de escape por un túnel (en el recuerdo del equipo: la moto entra al portal y **sube** por un tubo vertical).
6. Tiempo restante → puntos. También podías quedarte a seguir matando.
7. Si el reloj llega a 0: el **"scrub"**, un rayo lento que barre la arena y converge al podio central matando a quien toca. Las reseñas lo destacaron como la mejor mecánica.

### Armas
- **Primarias (todas las motos):**
  - Láser auto-apuntado, débil, cuyo daño crece mientras mantienes el blanco.
  - Electro-barrera: estela eléctrica detrás de la moto mientras mantienes la tecla; muerte instantánea al chocarla; cantidad limitada.
- **Secundarias (pickups, 3 slots, se pueden repetir):** misil teledirigido, embestida con nitro (lock + ram), onda de choque (área), drenador de energía, espada iónica (rayo que incapacita / bloquea controles).
- **Ítems:** escudo temporal / invulnerabilidad, orbes de salud, créditos de vida, llaves de color (rojo/verde/azul) para zonas cerradas, invisibilidad.

### Peligros
- **Torres de fusión:** pirámides pequeñas (rojo con punta blanca). Si brillan, explotan en radio al recibir un disparo o un choque. Truco conocido: meterse en una perseguido y **saltar** justo antes; la explosión pasa por debajo.
- Las motos **saltan**.

### Muerte
- La moto destruida queda como una pira de fuego vertical.
- El piloto puede eyectarse; matarlo a pie da un **"Mercy Kill"** con puntos extra.

### HUD (de capturas)
Arriba: llaves, timer, estado (`N KILLS LEFT` / `ADVANCE`), puntaje, kills. Centro: kill feed (`X KILLED Y WITH ARMA`), avisos (`MISSILE PICKED UP`, `YOU'VE BEEN LOCKED ON`). Abajo: ícono de arma primaria, 3 slots secundarios, barra en color del Runner, % de integridad, `WARNING` rojo, `IN AREA N`, radar con marcadores de borde, fila de indicadores (probables créditos de vida). Marcador triangular sobre el blanco fijado. Reloj gigante diegético en algunas paredes.

### Arte
Siluetas muy distintas por Runner; HUD teñido con el color del Runner; cada Dominio con paleta propia (azul tech, morado, rojo/marrón); sprites billboard para fuego y explosiones; franjas de peligro amarillo/negro en rampas.

## Fallos documentados del original (a corregir)

| # | Fallo | Nuestra solución |
|---|---|---|
| F1 | Todos reaparecían en el centro: quedarse ahí era una fuente infinita de kills fáciles | Área 0 es **zona franca** permanente (sin daño) — ver [D-01](01_GDD.md#decisiones-de-diseño) |
| F2 | Todas las armas aparecían en los primeros niveles; nada nuevo después | Desbloqueo progresivo de armas e ítems por Dominio |
| F3 | Velocidad y armas casi no se notaban; solo blindaje y manejo importaban | Fórmulas de stats con efecto perceptible ([03](03_RUNNERS.md)) |
| F4 | Campaña muy corta (una tarde) | Modificadores por Dominio, dificultad IA escalonada, desafíos |
| F5 | Bug: atravesar una pared y disparar desde dentro | Colisiones con volumen sólido, daño de área con línea de visión |
| F6 | A 640x480 era difícil distinguir enemigos de geometría | Siluetas + contorno de color del Runner + marcadores |

## Incógnitas (no verificables sin jugar el demo)

- Valores exactos de daño, duración de efectos, velocidades.
- Significado exacto de la fila de indicadores verdes del HUD.
- Si el hub era zona segura siempre o solo al inicio de la ronda (recuerdo del equipo: no se podía hacer daño al principio).
- Máximo de jugadores en LAN (las fuentes dicen 6 u 8).

Nada de esto bloquea: los números los definimos nosotros en [02](02_COMBATE_Y_BALANCE.md). Si alguien juega el **demo oficial** (Dominio 1 completo, distribución libre, disponible en Internet Archive) puede registrar mediciones en un issue con etiqueta `research`.

## Fuentes

- [DeathDrome — Wikipedia](https://en.wikipedia.org/wiki/DeathDrome)
- [DeathDrome Review — GameSpot](https://www.gamespot.com/reviews/deathdrome-review/1900-2538557/)
- [Death Drome — Giant Bomb](https://giantbomb.com/wiki/Games/Death_Drome)
- [The Collection Chamber: Death Drome](https://collectionchamber.blogspot.com/p/death-drome.html)
- [DeathDrome — The Computer Show](http://www.thecomputershow.com/computershow/reviews/deathdrome.htm)
- [Home of the Underdogs](https://www.homeoftheunderdogs.net/game.php?id=3038)
- [DeathDrome cheats (contraseñas de Dominio) — GamesRadar](https://www.gamesradar.com/deathdrome/cheats/)
- [Cheatbook (bug de la pared)](https://www.cheatbook.de/files/deathdrome.htm)
- [Hilo "Death Drome II" — comunidad ddrome](https://ddrome.proboards.com/thread/72/death-drome-ii)
- [DeathDrome Demo — Internet Archive](https://archive.org/details/DDROME)
