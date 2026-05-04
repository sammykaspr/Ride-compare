from ..config import get_pricing_config
from ..schemas import LatLng


def build_deep_link(provider_key: str, pickup: LatLng, drop: LatLng, platform: str = "web") -> str:
    cfg = get_pricing_config()["providers"]
    links = cfg[provider_key]["deep_link"]
    template = links.get(platform) or links.get("web") or ""
    return template.format(
        pickup_lat=pickup.lat,
        pickup_lng=pickup.lng,
        drop_lat=drop.lat,
        drop_lng=drop.lng,
    )
