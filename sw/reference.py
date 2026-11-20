#!/usr/bin/env python3
# Referencia en Python para el Pochoco Trader.
#
# Uso:
#   python reference.py          -> corre con umbral 8
#   python reference.py 5        -> corre con umbral 5
#   python reference.py barrido  -> compara umbrales de 0 a 20

import csv
import sys
from pathlib import Path


CAJA_INICIAL = 10000
COMISION = 5
MAX_ACCIONES = 63
VENTANA = 4
UMBRAL = 8

ARCHIVO_PROYECTO = Path(__file__).resolve().parent.parent
ARCHIVO_SERIE = ARCHIVO_PROYECTO / "practica_meta.csv"
ARCHIVO_SALIDA = Path(__file__).resolve().parent / "reference_decisions.csv"


def leer_precios(archivo_csv):
    """Lee las columnas tick y price del archivo de práctica."""
    precios = []

    with open(archivo_csv, newline="", encoding="utf-8-sig") as archivo:
        lector = csv.DictReader(archivo)
        for fila in lector:
            if not fila or not fila.get("tick"):
                continue

            tick = int(fila["tick"])
            precio = int(fila["price"])

            if precio < 1 or precio > 255:
                raise ValueError("El precio debe estar entre 1 y 255.")
            if precios and tick != precios[-1][0] + 1:
                raise ValueError("Los ticks del archivo deben ir en orden y sin saltos.")

            precios.append((tick, precio))

    if len(precios) == 0:
        raise ValueError("El archivo no tiene precios.")

    return precios


def ejecutar_orden(decision, precio, caja, acciones):
    """Aplica al precio actual la decisión que llegó del tick anterior."""
    accion = decision >> 6
    cantidad = decision & 63
    cantidad_ejecutada = 0

    if accion == 1:  # Comprar
        alcanza = (caja - COMISION) // precio
        if alcanza < 0:
            alcanza = 0
        if cantidad > alcanza:
            cantidad = alcanza

        if cantidad > 0:
            caja = caja - cantidad * precio - COMISION
            acciones = acciones + cantidad
            cantidad_ejecutada = cantidad

    elif accion == 2:  # Vender
        if cantidad > acciones:
            cantidad = acciones

        if cantidad > 0 and caja + cantidad * precio >= COMISION:
            caja = caja + cantidad * precio - COMISION
            acciones = acciones - cantidad
            cantidad_ejecutada = cantidad

    return caja, acciones, cantidad_ejecutada


def decidir(precio, precios_anteriores, acciones, umbral):
    """Compara el precio actual con la media de los cuatro precios previos."""
    if len(precios_anteriores) < VENTANA:
        return 0  # Mantener durante el período inicial

    suma = sum(precios_anteriores)

    # Multiplicar por 4 evita usar división para calcular el promedio.
    if precio * VENTANA > suma + umbral * VENTANA and acciones == 0:
        return (1 << 6) | MAX_ACCIONES  # Comprar hasta 63

    if precio * VENTANA < suma - umbral * VENTANA and acciones > 0:
        return (2 << 6) | MAX_ACCIONES  # Vender hasta 63

    return 0


def simular(precios, umbral):
    """Simula la estrategia y lleva una copia local de caja y acciones."""
    caja = CAJA_INICIAL
    acciones = 0
    decision_pendiente = 0
    precios_anteriores = []

    ordenes = 0
    comisiones = 0
    patrimonio_maximo = CAJA_INICIAL
    perdida_maxima = 0
    filas = []

    for tick, precio in precios:
        decision_ejecutada = decision_pendiente
        caja, acciones, cantidad = ejecutar_orden(
            decision_ejecutada, precio, caja, acciones
        )

        if cantidad > 0:
            ordenes += 1
            comisiones += COMISION

        patrimonio = caja + acciones * precio
        if patrimonio > patrimonio_maximo:
            patrimonio_maximo = patrimonio
        perdida = patrimonio_maximo - patrimonio
        if perdida > perdida_maxima:
            perdida_maxima = perdida

        decision_nueva = decidir(precio, precios_anteriores, acciones, umbral)
        filas.append(
            {
                "tick": tick,
                "price": precio,
                "threshold": umbral,
                "decision_executed": f"{decision_ejecutada:02X}",
                "quantity_executed": cantidad,
                "decision_written": f"{decision_nueva:02X}",
                "cash": caja,
                "shares": acciones,
                "wealth": patrimonio,
                "peak": patrimonio_maximo,
                "drawdown": perdida,
            }
        )

        precios_anteriores.append(precio)
        if len(precios_anteriores) > VENTANA:
            precios_anteriores.pop(0)
        decision_pendiente = decision_nueva

    resultado = {
        "patrimonio": caja + acciones * precios[-1][1],
        "ordenes": ordenes,
        "comisiones": comisiones,
        "perdida_maxima": perdida_maxima,
    }
    return filas, resultado


def comprar_y_mantener(precios):
    """Compra al primer precio y conserva las acciones hasta el final."""
    caja = CAJA_INICIAL
    acciones = 0
    ordenes = 0
    comisiones = 0
    patrimonio_maximo = CAJA_INICIAL
    perdida_maxima = 0

    for numero, par in enumerate(precios):
        precio = par[1]

        if numero == 0:
            cantidad = (caja - COMISION) // precio
            caja = caja - cantidad * precio - COMISION
            acciones = cantidad
            ordenes = 1
            comisiones = COMISION

        patrimonio = caja + acciones * precio
        if patrimonio > patrimonio_maximo:
            patrimonio_maximo = patrimonio
        perdida = patrimonio_maximo - patrimonio
        if perdida > perdida_maxima:
            perdida_maxima = perdida

    return {
        "patrimonio": caja + acciones * precios[-1][1],
        "ordenes": ordenes,
        "comisiones": comisiones,
        "perdida_maxima": perdida_maxima,
    }


def guardar_csv(filas):
    """Guarda las decisiones ejecutadas/escritas y la cartera tick a tick."""
    columnas = [
        "tick",
        "price",
        "threshold",
        "decision_executed",
        "quantity_executed",
        "decision_written",
        "cash",
        "shares",
        "wealth",
        "peak",
        "drawdown",
    ]

    with open(ARCHIVO_SALIDA, "w", newline="", encoding="utf-8") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=columnas)
        escritor.writeheader()
        escritor.writerows(filas)


def mostrar_resultado(nombre, resultado):
    print(
        f"{nombre:22} patrimonio={resultado['patrimonio']:>8}  "
        f"órdenes={resultado['ordenes']:>5}  "
        f"comisiones={resultado['comisiones']:>6}  "
        f"pérdida máxima={resultado['perdida_maxima']:>6}"
    )


def main():
    archivo_csv = ARCHIVO_SERIE
    modo = sys.argv[1] if len(sys.argv) > 1 else ""

    if modo == "barrido":
        if len(sys.argv) > 2:
            archivo_csv = Path(sys.argv[2])
    else:
        umbral = UMBRAL
        if modo:
            umbral = int(modo)
        if len(sys.argv) > 2:
            archivo_csv = Path(sys.argv[2])

    precios = leer_precios(archivo_csv)
    comprar_mantener = comprar_y_mantener(precios)

    print(f"Serie: {archivo_csv} ({len(precios)} ticks)")
    mostrar_resultado("No operar", {
        "patrimonio": CAJA_INICIAL,
        "ordenes": 0,
        "comisiones": 0,
        "perdida_maxima": 0,
    })
    mostrar_resultado("Comprar y mantener", comprar_mantener)

    if modo == "barrido":
        for valor in range(21):
            _, resultado = simular(precios, valor)
            mostrar_resultado(f"MA4 umbral {valor}", resultado)
        return

    filas, resultado = simular(precios, umbral)
    guardar_csv(filas)
    print(f"Umbral usado: {umbral}")
    print(f"Decisiones guardadas en: {ARCHIVO_SALIDA}")
    mostrar_resultado("Promedio móvil 4", resultado)


if __name__ == "__main__":
    main()
