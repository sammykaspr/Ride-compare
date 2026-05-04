from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .db import create_all, init_engine
from .routes import estimate, fares, surge
from .services.surge_model import load_model


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_engine()
    try:
        await create_all()
    except Exception as e:
        print(f"[startup] DB unavailable, /fares/log will fail until reachable: {e}")
    load_model()
    yield


app = FastAPI(title="RideCompare API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


app.include_router(estimate.router, tags=["estimate"])
app.include_router(fares.router, tags=["fares"])
app.include_router(surge.router, tags=["surge"])
