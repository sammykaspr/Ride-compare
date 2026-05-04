from fastapi import APIRouter

from ..schemas import SurgePredictRequest, SurgePredictResponse
from ..services.surge_model import predict_surge

router = APIRouter()


@router.post("/surge/predict", response_model=SurgePredictResponse)
async def surge_predict(req: SurgePredictRequest) -> SurgePredictResponse:
    mult, conf, source = predict_surge(req.hour, req.weekday)
    return SurgePredictResponse(surge_multiplier=mult, confidence=conf, source=source)
