import os
from datetime import datetime
from typing import Any

import joblib

from ..config import get_pricing_config, get_settings

_model: Any = None


def load_model() -> None:
    global _model
    path = get_settings().surge_model_path
    if os.path.exists(path):
        try:
            _model = joblib.load(path)
        except Exception:
            _model = None


def get_heuristic_surge(hour: int) -> float:
    h = get_pricing_config().get("surge_heuristic", {})
    return float(h.get("hours", {}).get(str(hour), h.get("default", 1.0)))


def predict_surge(hour: int, weekday: int) -> tuple[float, float, str]:
    """Returns (multiplier, confidence, source). Source is 'model' or 'heuristic'."""
    if _model is not None:
        try:
            import numpy as np

            x = np.array([[hour, weekday]], dtype=float)
            mult = float(_model.predict(x)[0])
            return round(mult, 2), 0.7, "model"
        except Exception:
            pass
    return get_heuristic_surge(hour), 0.5, "heuristic"


def current_surge() -> float:
    now = datetime.now()
    mult, _, _ = predict_surge(now.hour, now.weekday())
    return mult
