from fastapi import APIRouter

from ..schemas import EstimateRequest, EstimateResponse
from ..services.distance import get_distance
from ..services.pricing import build_options
from ..services.recommendation import best_picks
from ..services.surge_model import current_surge

router = APIRouter()


@router.post("/estimate", response_model=EstimateResponse)
async def estimate(req: EstimateRequest) -> EstimateResponse:
    d = await get_distance(req.pickup, req.drop)
    surge = current_surge()
    options = build_options(d.distance_km, d.duration_min, surge, req.pickup, req.drop)
    options.sort(key=lambda o: o.price_min)
    return EstimateResponse(
        distance_km=d.distance_km,
        duration_minutes=d.duration_min,
        options=options,
        recommendations=best_picks(options),
        used_mock=d.used_mock,
    )
