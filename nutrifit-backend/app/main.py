"""FastAPI application entrypoint.

Run locally:
    uvicorn app.main:app --reload

In production (Render/Fly/Railway/Docker) use the same module path:
    uvicorn app.main:app --host 0.0.0.0 --port $PORT
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import barcode, health, meal, search
from app.services.openfoodfacts import OpenFoodFactsClient
from app.version import __version__

log = logging.getLogger("nutrifit")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.off_client = OpenFoodFactsClient(settings)
    log.info(
        "nutrifit-backend started env=%s version=%s ai=%s",
        settings.environment,
        __version__,
        "on" if settings.openai_api_key else "off (stub)",
    )
    try:
        yield
    finally:
        await app.state.off_client.aclose()


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="NutriFit Backend",
        version=__version__,
        description=(
            "Backend for the NutriFit Flutter app. Three product endpoints "
            "(barcode lookup, food search, meal-image estimation) plus a "
            "health check. Owned by Esma Krnjić."
        ),
        lifespan=lifespan,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.cors_origins),
        allow_credentials=False,
        allow_methods=["GET", "POST", "OPTIONS"],
        allow_headers=["*"],
    )
    app.include_router(health.router)
    app.include_router(barcode.router)
    app.include_router(search.router)
    app.include_router(meal.router)
    return app


app = create_app()
