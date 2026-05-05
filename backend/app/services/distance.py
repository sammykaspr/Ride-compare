from dataclasses import dataclass
from math import asin, cos, radians, sin, sqrt
from typing import Optional

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


async def _via_google_routes(pickup: LatLng, drop: LatLng, key: str) -> Optional[DistanceResult]:
    url = "https://routes.googleapis.com/directions/v2:computeRoutes"
    headers = {
        "X-Goog-Api-Key": key,
        "X-Goog-FieldMask": "routes.distanceMeters,routes.duration",
        "Content-Type": "application/json",
    }
    body = {
        "origin": {"location": {"latLng": {"latitude": pickup.lat, "longitude": pickup.lng}}},
        "destination": {"location": {"latLng": {"latitude": drop.lat, "longitude": drop.lng}}},
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE",
    }
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.post(url, headers=headers, json=body)
            data = r.json()
        route = data["routes"][0]
        d_km = route["distanceMeters"] / 1000.0
        dur_s = float(route["duration"].rstrip("s"))
        return DistanceResult(round(d_km, 2), round(dur_s / 60.0, 1), used_mock=False)
    except (httpx.HTTPError, KeyError, IndexError, ValueError):
        return None


async def _via_osrm(pickup: LatLng, drop: LatLng) -> Optional[DistanceResult]:
    """Public OSRM demo. Free, no auth, dev-grade only — rate limited."""
    url = (
        f"https://router.project-osrm.org/route/v1/driving/"
        f"{pickup.lng},{pickup.lat};{drop.lng},{drop.lat}"
    )
    try:
        async with httpx.AsyncClient(timeout=10) as c:
            r = await c.get(url, params={"overview": "false"})
            data = r.json()
        if data.get("code") != "Ok" or not data.get("routes"):
            return None
        route = data["routes"][0]
        return DistanceResult(
            round(route["distance"] / 1000.0, 2),
            round(route["duration"] / 60.0, 1),
            used_mock=False,
        )
    except (httpx.HTTPError, KeyError, IndexError, ValueError):
        return None


async def get_distance(pickup: LatLng, drop: LatLng) -> DistanceResult:
    s = get_settings()
    if s.use_mock_distance:
        return _mock(pickup, drop)

    if s.google_maps_api_key:
        google = await _via_google_routes(pickup, drop, s.google_maps_api_key)
        if google is not None:
            return google

    osrm = await _via_osrm(pickup, drop)
    if osrm is not None:
        return osrm

    return _mock(pickup, drop)
