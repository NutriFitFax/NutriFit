"""Text search endpoint. Backs REQ-SCH-1/2/3/4."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from app.schemas import SearchResult
from app.services.openfoodfacts import OpenFoodFactsClient, OpenFoodFactsError

router = APIRouter(prefix="/search", tags=["search"])


def get_off_client(request: Request) -> OpenFoodFactsClient:
    return request.app.state.off_client


@router.get(
    "",
    response_model=SearchResult,
    responses={502: {"description": "Upstream OpenFoodFacts error"}},
    summary="Search for foods by free-text query",
)
async def search(
    q: str = Query(..., min_length=1, max_length=120, description="Search terms"),
    page: int = Query(1, ge=1, le=50),
    page_size: int = Query(20, ge=1, le=50),
    client: OpenFoodFactsClient = Depends(get_off_client),
) -> SearchResult:
    try:
        items, total = await client.search(q, page=page, page_size=page_size)
    except OpenFoodFactsError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    return SearchResult(
        query=q, page=page, page_size=page_size, total=total, items=items
    )
