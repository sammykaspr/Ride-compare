from typing import Optional

from pydantic import BaseModel, Field


class LatLng(BaseModel):
    lat: float
    lng: float


class EstimateRequest(BaseModel):
    pickup: LatLng
    drop: LatLng
    pickup_address: Optional[str] = None
    drop_address: Optional[str] = None


class RideOption(BaseModel):
    provider: str
    provider_label: str
    ride_type_id: str
    ride_type_label: str
    price_min: float
    price_max: float
    eta_minutes: int
    duration_minutes: float
    distance_km: float
    surge_multiplier: float
    deep_link: str


class Recommendations(BaseModel):
    cheapest: Optional[str] = None
    fastest: Optional[str] = None
    best_value: Optional[str] = None


class EstimateResponse(BaseModel):
    distance_km: float
    duration_minutes: float
    options: list[RideOption]
    recommendations: Recommendations
    used_mock: bool = False


class FareLogIn(BaseModel):
    provider: str
    ride_type: str
    pickup: LatLng
    drop: LatLng
    distance_km: float
    duration_min: float
    actual_fare: float
    estimated_fare: float


class SurgePredictRequest(BaseModel):
    hour: int = Field(ge=0, le=23)
    weekday: int = Field(ge=0, le=6)
    provider: str = "uber"


class SurgePredictResponse(BaseModel):
    surge_multiplier: float
    confidence: float
    source: str
