"""Pluggable scraper interface — no working implementations.

Major ride apps (Uber, Ola, Rapido, Namma Yatri) use signed, device-fingerprinted
mobile API requests, not scrape-able web flows. Their public sites do not return
real-time price quotes without an authenticated session, and they rate-limit and
block scrapers aggressively.

If you find a legitimate public source for a provider's quote (e.g. a partner
API or a public estimate widget), implement this protocol and register the
scraper. The estimate route can then prefer scraper results over the heuristic.
"""
from dataclasses import dataclass
from typing import Optional, Protocol

from ..schemas import LatLng


@dataclass
class ScraperResult:
    price_min: float
    price_max: float
    eta_minutes: int


class ProviderScraper(Protocol):
    name: str

    async def quote(self, pickup: LatLng, drop: LatLng) -> Optional[ScraperResult]: ...


REGISTRY: dict[str, ProviderScraper] = {}


def register(scraper: ProviderScraper) -> None:
    REGISTRY[scraper.name] = scraper
