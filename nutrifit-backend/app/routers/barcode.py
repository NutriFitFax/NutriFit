"""Barcode lookup endpoint. Backs REQ-BAR-2 / REQ-BAR-5.

Returns 200 + Food on hit, 404 on miss, 502 on upstream failure, 422 on
invalid input.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Path, Request

from app.schemas import Food
from app.services.openfoodfacts import OpenFoodFactsClient, OpenFoodFactsError

router = APIRouter(prefix="/barcode", tags=["barcode"])


def get_off_client(request: Request) -> OpenFoodFactsClient:
    return request.app.state.off_client


@router.get(
    "/{barcode}",
    response_model=Food,
    responses={
        404: {"description": "Product not found in OpenFoodFacts"},
        502: {"description": "Upstream OpenFoodFacts error"},
    },
    summary="Look up a product by barcode (EAN/UPC)",
)
async def get_by_barcode(
    barcode: str = Path(
        ...,
        min_length=6,
        max_length=20,
        pattern=r"^\d+$",
        description="EAN-8/13 or UPC numeric barcode",
    ),
    client: OpenFoodFactsClient = Depends(get_off_client),
) -> Food:
    try:
        food = await client.get_by_barcode(barcode)
    except OpenFoodFactsError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    if food is None:
        raise HTTPException(status_code=404, detail="product not found")
    return food
