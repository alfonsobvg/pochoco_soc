# Barrido de umbral y ventana

Se evaluaron 33620 combinaciones: ventana (W) de 1 a 20 ticks, umbral absoluto de compra (C) de 0 a 40 unidades normalizadas y umbral absoluto de venta (V) de 0 a 40. Cada operación solicita hasta 63 acciones; la compra se limita a la caja; se cobra comisión 5; y la decisión se ejecuta en el tick siguiente. La cartera final incluye acciones valoradas al último precio, aunque sigan abiertas.

El cálculo reproduce en esta sesión la lógica de `reference.py` con una ventana variable. No pude invocar el archivo Python directamente porque no hay un intérprete Python funcional disponible en el entorno.

Las combinaciones se ordenaron de tres maneras. **Serie completa:** mayor patrimonio final en 86 ticks; empates favorecen menor drawdown y menos órdenes. **Cuatro tramos:** mayor suma del patrimonio final al correr cada tramo como una simulación nueva; empates favorecen menor peor drawdown y menos órdenes. **Promedio:** mayor promedio entre el retorno de la serie completa y el retorno promedio de los cuatro tramos; empates favorecen menor drawdown global y menos órdenes. Cada simulación comienza con 10.000 de caja y cero acciones.

El promedio balanceado es solo un criterio comparativo, no una medida financiera universal. Las cuatro ventanas son segmentos consecutivos de la misma historia de IBM; reiniciar la cartera en cada segmento las convierte en pruebas de escenario, no en cuatro acciones independientes.

## Mejores por criterio

### Serie completa

| # | Parámetros | Patrimonio final | Órdenes | Drawdown máximo |
|---:|---|---:|---:|---:|
| 1 | W=5, C=7, V=15 | 25206 | 8 | 4168 |
| 2 | W=5, C=7, V=16 | 25206 | 8 | 4168 |
| 3 | W=5, C=7, V=17 | 25206 | 8 | 4168 |
| 4 | W=5, C=7, V=18 | 25206 | 8 | 4168 |
| 5 | W=5, C=7, V=19 | 25206 | 8 | 4168 |

Mejor: **W=5, C=7, V=15**. Resultado: 25206, 8 órdenes, drawdown 4168.

### Suma de los cuatro tramos

| # | Parámetros | Patrimonio total (inicio 40.000) | Órdenes totales | Peor drawdown de un tramo |
|---:|---|---:|---:|---:|
| 1 | W=2, C=15, V=26 | 49273 | 6 | 3591 |
| 2 | W=2, C=14, V=26 | 48963 | 8 | 3591 |
| 3 | W=1, C=7, V=0 | 48218 | 35 | 4931 |
| 4 | W=1, C=7, V=1 | 48218 | 35 | 4931 |
| 5 | W=1, C=8, V=0 | 48218 | 35 | 4931 |

Mejor: **W=2, C=15, V=26**. Resultado: 49273, 6 órdenes, peor drawdown 3591.

### Promedio entre serie completa y tramos

| # | Parámetros | Patrimonio serie completa | Patrimonio total de tramos | Órdenes completa/tramos | Drawdown global | Retorno promedio |
|---:|---|---:|---:|---:|---:|---:|
| 1 | W=2, C=15, V=26 | 24523 | 49273 | 6/6 | 4168 | 84.21% |
| 2 | W=5, C=7, V=15 | 25206 | 45623 | 8/6 | 4168 | 83.06% |
| 3 | W=5, C=7, V=16 | 25206 | 45623 | 8/6 | 4168 | 83.06% |
| 4 | W=5, C=7, V=17 | 25206 | 45623 | 8/6 | 4168 | 83.06% |
| 5 | W=5, C=7, V=18 | 25206 | 45623 | 8/6 | 4168 | 83.06% |

Mejor compromiso según este criterio: **W=2, C=15, V=26**. Serie completa: 24523, 6 órdenes, drawdown 4168. Tramos: 49273, 6 órdenes, peor drawdown 3591. Retorno promedio: 84.21%.

## Comparación con los parámetros actuales

La configuración anterior usada como referencia (W=4, C=8, V=7) termina en 14015 en la serie completa, con 16 órdenes y drawdown 6640. La suma de los tramos es 38284 (inicio 40.000), con 14 órdenes y drawdown peor de 4625.

Estos resultados están ajustados sobre esta misma serie corta; no son una recomendación de umbrales para precios futuros. Varias combinaciones que terminan empatadas pueden tener umbrales diferentes porque no generan señales distintas en estos datos.
