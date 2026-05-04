from dataclasses import dataclass
from math import asin, cos, radians, sin, sqrt

import httpx

from ..config import get_settings
from ..schemas import LatLng


@dataclass
class DistanceResult:
    distance_km: float
    duration_min: float
    used_mock: bool


def haversine_km(a: LatLng, b: LatLng) -> float:
    r = 6371.0
    lat1, lat2 = radians(a.lat), radians(b.lat)
    dlat = lat2 - lat1
    dlng = radians(b.lng - a.lng)
    h = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
    return 2 * r * asin(sqrt(h))


def _mock(pickup: LatLng, drop: LatLng) -> DistanceResult:
    crow = haversine_km(pickup, drop)
    d_km = round(crow * 1.3, 2)
    dur = round((d_km / 25.0) * 60, 1)
    return DistanceResult(d_km, dur, used_mock=True)


async def get_distance(pickup: LatLng, drop: LatLng) -> DistanceResult:
    s = get_settings()
    if not s.google_maps_api_key or s.use_mock_distance:
        return _mock(pickup, drop)

    url = "https://maps.googleapis.com/maps/api/distancematrix/json"
    params = {
        "origins": f"{pickup.lat},{pickup.lng}",
        "destinations": f"{drop.lat},{drop.lng}",
        "mode": "driving",
        "key": s.google_maps_api_key,
    }
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(url, params=params)
            data = r.json()
        elem = data["rows"][0]["elements"][0]
        if elem.get("status") != "OK":
            return _mock(pickup, drop)
        d_km = elem["distance"]["value"] / 1000.0
        dur = elem["duration"]["value"] / 60.0
        return DistanceResult(round(d_km, 2), round(dur, 1), used_mock=False)
    except (httpx.HTTPError, KeyError, IndexError, ValueError):
        return _mock(pickup, drop)
