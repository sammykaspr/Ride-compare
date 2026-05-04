from ..config import get_pricing_config
from ..schemas import LatLng, RideOption
from .deeplink import build_deep_link


def estimate_fare(
    base: float,
    per_km: float,
    per_min: float,
    min_fare: float,
    distance_km: float,
    duration_min: float,
    surge: float,
) -> tuple[float, float]:
    """Returns (price_min, price_max) — applies surge then a ±10% band for uncertainty."""
    raw = base + per_km * distance_km + per_min * duration_min
    raw = max(raw, min_fare)
    surged = raw * surge
    return round(surged * 0.9), round(surged * 1.1)


def build_options(
    distance_km: float,
    duration_min: float,
    surge: float,
    pickup: LatLng,
    drop: LatLng,
) -> list[RideOption]:
    cfg = get_pricing_config()["providers"]
    options: list[RideOption] = []
    for prov_key, prov in cfg.items():
        for rt in prov["ride_types"]:
            pmin, pmax = estimate_fare(
                rt["base"],
                rt["per_km"],
                rt["per_min"],
                rt["min_fare"],
                distance_km,
                duration_min,
                surge,
            )
            options.append(
                RideOption(
                    provider=prov_key,
                    provider_label=prov["display_name"],
                    ride_type_id=rt["id"],
                    ride_type_label=rt["label"],
                    price_min=pmin,
                    price_max=pmax,
                    eta_minutes=rt["eta_minutes"],
                    duration_minutes=duration_min,
                    distance_km=distance_km,
                    surge_multiplier=surge,
                    deep_link=build_deep_link(prov_key, pickup, drop),
                )
            )
    return options
