# Validación completa del Proyecto 4

## Configuración

- Serie: `practica_meta.csv`, 20.000 ticks, precios entre 100 y 255.
- Programa: `sw/trade.s` → `sw/trade.hex` (105 instrucciones).
- Parámetros: ventana 5, umbral de compra 7, umbral de venta 15, solicitud máxima 63.
- Clock de simulación: 25 MHz (40 ns por ciclo); SPI: 9.500 ns por tick.
- Período simulado: 100.000 ns.

## Resultados financieros

| Estrategia | Patrimonio final | Órdenes | Comisiones | Pérdida máxima desde peak |
|---|---:|---:|---:|---:|
| No operar | 10.000 | 0 | 0 | 0 |
| Comprar al inicio y mantener | 9.695 | 1 | 5 | 9.300 |
| Media móvil 5, compra 7, venta 15 | 10.121 | 1 | 5 | 9.765 |

La estrategia solicitó una compra de 63 acciones en el tick 3.551 a precio 158; quedaron 41 unidades de efectivo. No realizó otra orden. El último tick fue 19.999, precio 160 y patrimonio 10.121.

## Métricas de ejecución

- Promedio por tick: 51,334 instrucciones, 119,721 ciclos, CPI 2,3324, 4,789 µs.
- Máximo IC: 371 instrucciones en tick 3.551.
- Máximo de ciclos/tiempo: 827 ciclos, 33.080 ns, en tick 3.551.
- Máximo CPI: 2,417 en tick 3.550.
- Presupuesto a 100.000 ns por ronda: 2.262 ciclos después de SPI; margen del peor caso: 1.435 ciclos (57.420 ns).
- Comparación de los 20.000 ticks contra la referencia Python: 0 diferencias en precio, decisión ejecutada, efectivo, acciones o patrimonio.
- Chequeos RTL: 4/4 aprobados.

Las métricas completas por tick están en `practica_meta_resultados_tick.csv`.

## Síntesis y place-and-route

- Top: `trade_top`, con SPI conectado y `sw/trade.hex` cargado.
- Yosys: 996 celdas `SB_LUT4` y 12 bloques `SB_RAM40_4K`.
- nextpnr HX1K/VQ100: 1.167/1.280 logic cells (91%) y 12/16 bloques RAM (75%).
- Frecuencia máxima estimada: 42,24 MHz; pasó la restricción de 25 MHz.
- `make trade_top.bin` terminó con código 0; bitstream generado: 32.220 bytes.

## Nota del entorno

Icarus generó `tb_p4.vvp`, pero `iverilog.exe` devolvió el código Windows `-1073741819` al terminar. `vvp` ejecutó el testbench hasta el final y reportó los cuatro chequeos aprobados. La advertencia de `$readmemh` corresponde a las 105 palabras del programa cargadas en una RAM de 512 palabras.
