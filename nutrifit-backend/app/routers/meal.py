"""Meal-image estimation endpoint. Backs REQ-IMG-1 / REQ-IMG-3."""

from __future__ import annotations

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from app.config import Settings, get_settings
from app.schemas import MealEstimate
from app.services.meal_estimator import MealEstimatorError, estimate

router = APIRouter(prefix="/estimate-meal", tags=["meal"])

_ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}


@router.post(
    "",
    response_model=MealEstimate,
    responses={
        413: {"description": "Image too large"},
        415: {"description": "Unsupported image type"},
        502: {"description": "AI provider error"},
    },
    summary="Estimate nutrition from a meal photo",
)
async def estimate_meal(
    image: UploadFile = File(..., description="JPEG/PNG/WebP meal photo"),
    settings: Settings = Depends(get_settings),
) -> MealEstimate:
    if image.content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=415,
            detail=f"unsupported content_type: {image.content_type}",
        )
    data = await image.read()
    if len(data) == 0:
        raise HTTPException(status_code=422, detail="empty image upload")
    if len(data) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"image exceeds {settings.max_upload_bytes} bytes",
        )
    try:
        return await estimate(settings, data, image.content_type)
    except MealEstimatorError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
