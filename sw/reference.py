#!/usr/bin/env python3
"""Referencia Python para la estrategia de promedio móvil de 4 ticks.

El programa calcula una decisión después de recibir cada precio. Esa decisión
se transmite en el siguiente tick, por lo que la contabilidad ejecuta primero
la decisión pendiente al precio actual y luego calcula la próxima decisión.
"""

from __future__ import annotations

import argparse
import csv
from collections import deque
from pathlib import Path


INITIAL_CASH = 10_000
COMMISSION = 5
MAX_QUANTITY = 63
WINDOW = 4

HOLD = 0b00
BUY = 0b01
SELL = 0b10
BUY_MAX = (BUY << 6) | MAX_QUANTITY
SELL_MAX = (SELL << 6) | MAX_QUANTITY

PROJECT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_PRICES = PROJECT_DIR / "practica_meta.csv"
DEFAULT_OUTPUT = PROJECT_DIR / "sw" / "reference_decisions.csv"


def load_prices(path: Path) -> list[tuple[int, int]]:
    """Lee una serie CSV con encabezado tick,price y precios de 1 a 255."""
    rows: list[tuple[int, int]] = []
    previous_tick: int | None = None

    with path.open("r", newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames is None or not {"tick", "price"}.issubset(reader.fieldnames):
            raise ValueError("El CSV debe tener las columnas tick,price.")

        for line_number, row in enumerate(reader, start=2):
            if not row or row.get("tick") is None:
                continue
            try:
                tick = int(row["tick"])
                price = int(row["price"])
            except (TypeError, ValueError) as error:
                raise ValueError(f"Fila {line_number}: tick y price deben ser enteros.") from error

            if not 1 <= price <= 255:
                raise ValueError(f"Fila {line_number}: el precio debe estar entre 1 y 255.")
            if previous_tick is not None and tick != previous_tick + 1:
                raise ValueError(f"Fila {line_number}: se esperaba tick {previous_tick + 1}, llegó {tick}.")

            rows.append((tick, price))
            previous_tick = tick

    if not rows:
        raise ValueError("El CSV no contiene precios.")
    return rows


def apply_order(decision: int, price: int, cash: int, shares: int) -> tuple[int, int, int]:
    """Aplica una decisión con las reglas de caja, acciones y comisión del curso."""
    action = decision >> 6
    requested = decision & 0x3F
    executed = 0

    if action == BUY:
        affordable = max(0, (cash - COMMISSION) // price)
        executed = min(requested, affordable)
        if executed > 0:
            cash -= executed * price + COMMISSION
            shares += executed
    elif action == SELL:
        executed = min(requested, shares)
        if executed > 0 and cash + executed * price >= COMMISSION:
            cash += executed * price - COMMISSION
            shares -= executed
        else:
            executed = 0

    return cash, shares, executed


def decide(
    price: int,
    previous_prices: deque[int],
    shares: int,
    threshold: int,
) -> int:
    """Compara el precio actual con el promedio de los cuatro precios previos."""
    if len(previous_prices) < WINDOW:
        return HOLD

    # 4 * price versus the sum avoids division and floating-point rounding.
    previous_sum = sum(previous_prices)
    scaled_threshold = threshold * WINDOW
    if price * WINDOW > previous_sum + scaled_threshold and shares == 0:
        return BUY_MAX
    if price * WINDOW < previous_sum - scaled_threshold and shares > 0:
        return SELL_MAX
    return HOLD


def simulate(
    prices: list[tuple[int, int]], threshold: int = 0
) -> tuple[list[dict[str, int | str]], dict[str, int]]:
    """Simula el retraso SPI y mantiene una copia local de la cartera oficial."""
    cash = INITIAL_CASH
    shares = 0
    pending_decision = 0
    history: deque[int] = deque(maxlen=WINDOW)

    orders = 0
    commissions = 0
    peak = INITIAL_CASH
    max_drawdown = 0
    details: list[dict[str, int | str]] = []

    for tick, price in prices:
        executed_decision = pending_decision
        cash, shares, quantity_executed = apply_order(
            executed_decision, price, cash, shares
        )
        if quantity_executed > 0:
            orders += 1
            commissions += COMMISSION

        wealth = cash + shares * price
        peak = max(peak, wealth)
        drawdown = peak - wealth
        max_drawdown = max(max_drawdown, drawdown)

        next_decision = decide(price, history, shares, threshold)
        details.append(
            {
                "tick": tick,
                "price": price,
                "threshold": threshold,
                "decision_executed": f"{executed_decision:02X}",
                "quantity_executed": quantity_executed,
                "decision_written": f"{next_decision:02X}",
                "cash": cash,
                "shares": shares,
                "wealth": wealth,
                "peak": peak,
                "drawdown": drawdown,
            }
        )

        history.append(price)
        pending_decision = next_decision

    summary = {
        "final_wealth": cash + shares * prices[-1][1],
        "orders": orders,
        "commissions": commissions,
        "max_drawdown": max_drawdown,
    }
    return details, summary


def buy_and_hold(prices: list[tuple[int, int]]) -> dict[str, int]:
    """Calcula la referencia que compra al primer precio y conserva las acciones."""
    cash = INITIAL_CASH
    shares = 0
    orders = 0
    commissions = 0
    peak = INITIAL_CASH
    max_drawdown = 0

    for index, (_, price) in enumerate(prices):
        if index == 0:
            quantity = max(0, (cash - COMMISSION) // price)
            if quantity > 0:
                cash -= quantity * price + COMMISSION
                shares += quantity
                orders += 1
                commissions += COMMISSION

        wealth = cash + shares * price
        peak = max(peak, wealth)
        max_drawdown = max(max_drawdown, peak - wealth)

    return {
        "final_wealth": cash + shares * prices[-1][1],
        "orders": orders,
        "commissions": commissions,
        "max_drawdown": max_drawdown,
    }


def write_decisions(path: Path, rows: list[dict[str, int | str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = [
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
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def print_summary(name: str, result: dict[str, int]) -> None:
    print(
        f"{name:22} patrimonio={result['final_wealth']:>8}  "
        f"órdenes={result['orders']:>5}  comisiones={result['commissions']:>6}  "
        f"pérdida máxima={result['max_drawdown']:>6}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prices", type=Path, default=DEFAULT_PRICES, help="CSV tick,price")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="CSV de decisiones y cartera")
    parser.add_argument(
        "--threshold",
        type=int,
        default=8,
        help="margen entero sobre/bajo el promedio móvil (por defecto: 0)",
    )
    parser.add_argument(
        "--sweep-max",
        type=int,
        help="compara umbrales desde 0 hasta este valor y no escribe el CSV de detalle",
    )
    args = parser.parse_args()

    if args.threshold < 0 or (args.sweep_max is not None and args.sweep_max < 0):
        parser.error("los umbrales no pueden ser negativos")

    prices = load_prices(args.prices)
    hold = buy_and_hold(prices)

    if args.sweep_max is not None:
        print(f"Serie: {args.prices} ({len(prices)} ticks)")
        print_summary("No operar", {
            "final_wealth": INITIAL_CASH,
            "orders": 0,
            "commissions": 0,
            "max_drawdown": 0,
        })
        print_summary("Comprar y mantener", hold)
        for threshold in range(args.sweep_max + 1):
            _, result = simulate(prices, threshold)
            print_summary(f"MA4 umbral {threshold}", result)
        return

    details, strategy = simulate(prices, args.threshold)
    write_decisions(args.output, details)

    print(f"Serie: {args.prices} ({len(prices)} ticks)")
    print(f"Umbral: {args.threshold}")
    print(f"Resultados guardados en: {args.output}")
    print_summary("No operar", {
        "final_wealth": INITIAL_CASH,
        "orders": 0,
        "commissions": 0,
        "max_drawdown": 0,
    })
    print_summary("Comprar y mantener", hold)
    print_summary("Promedio móvil 4", strategy)


if __name__ == "__main__":
    main()
