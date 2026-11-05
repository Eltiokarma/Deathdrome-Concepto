# Dominio 1 · Penal Altiplano

## Concepto (2 líneas)
Prisión de la meseta: hormigón, acero azul y señalética verde.
Cuatro patios cubiertos enseñan conducción, salto, cobertura y regreso al portal.

## Modificador
Ninguno. Tutorial implícito según [diseño de dominios](../04_DOMINIOS_Y_NIVELES.md).
**Estado: propuesta inicial PUR-070, 2026-11-05.** Plano de implantación, no nivel construido ni métricas de juego certificadas. No cambia balance.

## Plano (imagen en docs/dominios/img/)
![Implantación del Penal Altiplano](img/01_penal_altiplano.svg)

Vista superior: norte = −Z, este = +X; Y vertical. Centro del hub (0,0,0).
El dibujo fija envolventes y conexiones; coberturas, desvíos interiores y navegación quedan para blockout.
No hay pasajes secundarios ni puertas de llave en esta primera versión.

| Elemento | Coordenadas / dimensiones propuestas |
|---|---|
| Hub | Centro X/Z (0,0), diámetro 40 m |
| Portal | Centro (0,0), diámetro 10 m, podio 1.5 m; acceso mediante rampas ≤25° |
| Salas 1/2/3/4 | Centros (0,−52), (52,0), (0,52), (−52,0); cada una 36×36 m |
| Conexiones | Desde radio 20 hasta borde de sala a 34 m; longitud nominal 14 m, ancho 8 m |
| Compuertas | Umbrales cardinales del hub, 8×5 m; ajustar encuentro con pared curva sin grietas |
| Techo base | 5 m sobre suelo; sobre plataformas elevar a 6 m para conservar salto y margen |
| Alturas | Plataformas de 2 m; rampas de 6 m de desarrollo horizontal (18.4°), ancho 8 m |
| Spawns | Ocho puntos a radio 7 m, ángulos ±22.5° respecto a cada eje cardinal, mirando afuera |

## Áreas
Pickups/torres son reservas de diseño hasta implementar sus sistemas; no usar nodos ficticios como si funcionaran.

| Área | Tema | Ronda que abre | Pickups | Torres | Llave | Notas |
|---|---|---|---|---|---|---|
| 0 | Patio central | Siempre | 0 | 0 | No | Sin coberturas; SafeZone hasta umbrales, relojes y portal visibles |
| 1 | Patio de ingreso | R1 | 3 de misil + 1 salud | 2 | No | Plataforma lateral, dos rutas alrededor de cobertura |
| 2 | Taller | R1 | 3 de misil + 1 salud | 2 | No | Pilares y circuito de rampas, sin callejones |
| 3 | Galería | R2 | 4 de misil + 1 salud | 3 | No | Dos plataformas conectadas por recorrido de suelo |
| 4 | Patio de vigilancia | R3 | 4 de misil + 1 salud | 3 | No | Cruces y cobertura alternada, regreso legible al hub |

Distribuir coberturas cada 10–15 m dentro de salas; mantener pasos de 7–9 m.
Torres alejadas de entradas, ocultas a rayos desde el hub por deflectores interiores.
Un deflector en cada sala debe cortar la recta axial antes de 60 m y ofrecer dos pasos laterales, sin tapar el número de área.
**Las coordenadas de deflectores, torres y pickups deben fijarse y probarse en el blockout:** este plano no certifica aún líneas de tiro.
Compuertas cerradas sólidas y rojas; número ≥3 m visible desde hub; salida rotulada “SALIDA ↓ 0”.

## Rutas principales (Área 0 → cada sala, tiempo a vel. 23.5 m/s)

Las cuatro rutas son simétricas en planta. Son cotas inferiores de distancia, sin aceleración, desvíos ni obstáculos.

| Tramo | Distancia nominal | Tiempo ideal |
|---|---:|---:|
| Centro del hub → umbral | 20 m | 0.85 s |
| Umbral → entrada de sala | 14 m | 0.60 s |
| Centro del hub → centro de sala | 52 m | 2.21 s |
| Spawn → centro de sala (distancia recta) | 45.61 m | 1.94 s |

El centro contiene el portal: las rutas reales lo rodean. Medir desde spawns con Runner real; aceptación: cada sala alcanzable en ≤6 s a velocidad media. No presentar estos tiempos ideales como playtest.

## Puntos calientes esperados
- Salas 1–2: combate inicial por misiles, salida rápida del hub.
- Rampas y cruces: barreras esquivables, torres como riesgo legible.
- Retorno al portal tras cuota: entradas visibles y sin torres con línea directa al hub.

## Purga: contrato para implementación
Propuesta: un frente por sala abierta, desde borde exterior a su umbral (50 m nominales a 3.5 m/s ≈14.29 s), seguido por cierre del hub en 10 s. Mantener aviso a 0:30.
Cada frente debe barrer sala y conexión completas, incluidos rampas, pisos y plataformas; delimitar su volumen para no matar prematuramente en salas vecinas.
Salas cerradas no deben poder contener participantes ni generar refugios. El frente radial del sandbox queda separado.
La forma exacta, sincronización y cobertura deben verificarse con geometría física; no reutilizar radio 56/7 del ensayo como dimensiones del dominio.
D8 conserva su multiplicador previsto; no se aplica en Dominio 1.

## Riesgos (dónde se puede quedar atascado un bot o un jugador)
- Encuentros entre círculo del hub y conexiones rectangulares: soldar suelos, revisar esquinas.
- Podio: rampas y anillo de spawns no deben bloquearse mutuamente; probar ocho salidas.
- Deflectores: pueden crear callejones o rutas excesivas; ofrecer paso a ambos lados.
- Plataforma/techo: verificar salto y cámara con volumen real del Runner.
- Simetría: señalética y siluetas propias por sala para orientar al jugador.

## Entrega siguiente para Claude
1. Revisar esta propuesta contra métricas de docs/04 y concretar posiciones interiores.
2. Crear blockout en `game/levels/domain_01/`, consistente con estructura actual; conservar escenas de ensayo.
3. Integrar AreaTracker PUR-032 y compuertas PUR-036 por bloques separados; después navegación y Purga.
4. Validar checklist de docs/04: líneas ≤60 m, ausencia de callejones próximos a puertas, rutas ≤6 s, cobertura de Purga, colisiones y legibilidad.
5. Bots, 20 partidas sin atascos y benchmark con ocho Runners siguen pendientes; no marcar PUR-071 completo antes de comprobarlos.

No hay reserva activa de Codex al entregar esta ficha. PUR-070 tiene una propuesta documental; su aprobación de diseño y revisión del plano siguen pendientes.
