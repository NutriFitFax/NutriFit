"""Health + readiness endpoints. Used by Render/Fly/Uptime checks."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.config import Settings, get_settings
from app.schemas import HealthResponse
from app.version import __version__

router = APIRouter(tags=["health"])


@router.get("/", response_model=HealthResponse, summary="Service health")
@router.get("/health", response_model=HealthResponse, summary="Service health")
async def health(settings: Settings = Depends(get_settings)) -> HealthResponse:
    return HealthResponse(
        status="ok", environment=settings.environment, version=__version__
    )
