"""Train a surge predictor from sample data or the database.

Usage:
    python scripts/train_surge_model.py              # train from sample_fares.csv
    python scripts/train_surge_model.py --from-db    # train from logged fares

Saves surge_model.pkl next to this script. The backend loads it on startup.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).resolve().parent
SAMPLE = ROOT / "sample_fares.csv"
OUTPUT = ROOT / "surge_model.pkl"


def load_from_db() -> pd.DataFrame:
    import asyncio

    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine

    url = os.environ.get(
        "DATABASE_URL",
        "postgresql+asyncpg://postgres:postgres@localhost:5432/ridecompare",
    )

    async def fetch() -> pd.DataFrame:
        engine = create_async_engine(url)
        async with engine.connect() as conn:
            rows = (
                await conn.execute(
                    text(
                        "SELECT EXTRACT(HOUR FROM created_at) AS hour, "
                        "EXTRACT(DOW FROM created_at) AS weekday, "
                        "surge_observed AS surge "
                        "FROM fare_logs"
                    )
                )
            ).all()
        await engine.dispose()
        return pd.DataFrame(rows, columns=["hour", "weekday", "surge"])

    return asyncio.run(fetch())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--from-db", action="store_true")
    args = parser.parse_args()

    if args.from_db:
        df = load_from_db()
    else:
        df = pd.read_csv(SAMPLE)

    if len(df) < 10:
        print(f"Not enough samples ({len(df)}); need at least 10. Aborting.")
        return 1

    X = df[["hour", "weekday"]].astype(float).values
    y = df["surge"].astype(float).values

    if len(df) >= 30:
        X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42)
    else:
        X_tr, X_te, y_tr, y_te = X, X, y, y

    model = RandomForestRegressor(n_estimators=80, max_depth=6, random_state=42)
    model.fit(X_tr, y_tr)
    mae = mean_absolute_error(y_te, model.predict(X_te))

    joblib.dump(model, OUTPUT)
    print(f"Trained on {len(df)} rows. MAE={mae:.3f}. Saved to {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
