from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_db
from ..models import FareLog
from ..schemas import FareLogIn

router = APIRouter()


@router.post("/fares/log")
async def log_fare(payload: FareLogIn, db: AsyncSession = Depends(get_db)) -> dict:
    surge = payload.actual_fare / payload.estimated_fare if payload.estimated_fare > 0 else 1.0
    row = FareLog(
        provider=payload.provider,
        ride_type=payload.ride_type,
        pickup_lat=payload.pickup.lat,
        pickup_lng=payload.pickup.lng,
        drop_lat=payload.drop.lat,
        drop_lng=payload.drop.lng,
        distance_km=payload.distance_km,
        duration_min=payload.duration_min,
        actual_fare=payload.actual_fare,
        estimated_fare=payload.estimated_fare,
        surge_observed=round(surge, 2),
    )
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return {"ok": True, "id": row.id, "surge_observed": row.surge_observed}
