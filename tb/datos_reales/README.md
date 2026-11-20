# Series de prueba con datos reales

Estos archivos se generaron con cierres diarios de IBM (símbolo IBM) consultados desde la API de series diarias de Alpha Vantage. La serie más reciente de la respuesta tiene datos hasta el 19-11-2026. Se usa el campo de cierre diario, ordenado desde la fecha más antigua a la más reciente.

La muestra contiene 86 días de negociación. En todos los archivos de prueba se aplicó la misma conversión usando el mínimo y el máximo de la muestra completa: mínimo 205.77 USD y máximo 258.28 USD.

`price = 1 + floor(254 * (cierre - mínimo) / (máximo - mínimo) + 0.5)`

Así, los precios quedan entre 1 y 255. El proyecto trata el precio como positivo; se evita 0 para que la contabilidad pueda dividir por precio.

## Archivos

- `ibm_completa.csv`: los 86 cierres (ticks 1 a 86).
- `ibm_alza_jul_ago.csv`: ticks originales 1–20, 2026-07-22 a 2026-08-18; el cierre sube de 205.77 a 232.67 USD.
- `ibm_lateral_ago_sep.csv`: ticks originales 21–40, 2026-08-19 a 2026-09-16; el cierre inicial y final son parecidos.
- `ibm_baja_sep_oct.csv`: ticks originales 41–60, 2026-09-17 a 2026-10-14; el cierre baja de 237.75 a 227.88 USD.
- `ibm_volatil_oct_nov.csv`: ticks originales 61–86, 2026-10-15 a 2026-11-19; incluye un alza y una reversión.
- `ibm_cierres_fuente.csv`: datos de apoyo con fecha, cierre original en USD y valor normalizado.

Los CSV de prueba tienen únicamente `tick,price`, compatible con el formato que lee `reference.py`. Las trazas de simulación con umbrales absolutos 8/7 están en `sw/resultados_reales`.

Fuente: https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=IBM&apikey=demo . La documentación indica que `TIME_SERIES_DAILY` entrega precios diarios raw, incluyendo cierre, y ofrece ejemplos de IBM: https://www.alphavantage.co/documentation/.

