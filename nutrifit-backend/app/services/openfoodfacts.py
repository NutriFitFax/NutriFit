"""Thin wrapper around the OpenFoodFacts public API.

OpenFoodFacts is a free, open product database. Docs:
  - Product by barcode: GET /api/v2/product/{barcode}.json
  - Search:             GET /cgi/search.pl?search_terms=...&json=1

We map their (often inconsistent) field names into our stable Food schema so
the Flutter side never has to deal with OFF quirks.
"""

from __future__ import annotations

from typing import Any

import httpx

from app.config import Settings
from app.schemas import Food, Macros


class OpenFoodFactsError(Exception):
    """Raised when the upstream API returns an unexpected response."""


def _to_float(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        f = float(value)
    except (TypeError, ValueError):
        return None
    # OFF sometimes returns negative placeholders; clamp to >= 0.
    return max(f, 0.0)


def _build_macros(nutriments: dict[str, Any]) -> Macros:
    return Macros(
        calories_kcal=_to_float(nutriments.get("energy-kcal_100g"))
        or _to_float(nutriments.get("energy-kcal"))
        or 0.0,
        protein_g=_to_float(nutriments.get("proteins_100g")) or 0.0,
        carbs_g=_to_float(nutriments.get("carbohydrates_100g")) or 0.0,
        fat_g=_to_float(nutriments.get("fat_100g")) or 0.0,
        fiber_g=_to_float(nutriments.get("fiber_100g")),
        sugar_g=_to_float(nutriments.get("sugars_100g")),
        salt_g=_to_float(nutriments.get("salt_100g")),
    )


def _parse_serving_size_g(raw: Any) -> float | None:
    """OFF stores serving size as a free-form string like '30 g' or '250 ml'."""
    if not raw or not isinstance(raw, str):
        return None
    cleaned = raw.lower().replace(",", ".").strip()
    number = ""
    for ch in cleaned:
        if ch.isdigit() or ch == ".":
            number += ch
        elif number:
            break
    try:
        return float(number) if number else None
    except ValueError:
        return None


def _to_food(product: dict[str, Any], fallback_id: str) -> Food | None:
    if not product:
        return None
    name = (
        product.get("product_name")
        or product.get("product_name_en")
        or product.get("generic_name")
    )
    if not name:
        return None
    nutriments = product.get("nutriments") or {}
    return Food(
        id=str(product.get("code") or product.get("_id") or fallback_id),
        name=str(name).strip(),
        brand=(product.get("brands") or "").split(",")[0].strip() or None,
        image_url=product.get("image_front_url") or product.get("image_url"),
        serving_size_g=_parse_serving_size_g(product.get("serving_size")),
        macros_per_100g=_build_macros(nutriments),
    )


class OpenFoodFactsClient:
    """Async client. One instance per app, reused across requests."""

    def __init__(self, settings: Settings, client: httpx.AsyncClient | None = None):
        self._settings = settings
        self._client = client or httpx.AsyncClient(
            base_url=settings.openfoodfacts_base_url,
            timeout=settings.http_timeout,
            headers={"User-Agent": settings.user_agent},
        )

    async def aclose(self) -> None:
        await self._client.aclose()

    async def get_by_barcode(self, barcode: str) -> Food | None:
        try:
            resp = await self._client.get(f"/api/v2/product/{barcode}.json")
        except httpx.HTTPError as exc:
            raise OpenFoodFactsError(f"upstream error: {exc}") from exc
        if resp.status_code == 404:
            return None
        if resp.status_code >= 500:
            raise OpenFoodFactsError(f"upstream {resp.status_code}")
        data = resp.json()
        if int(data.get("status", 0)) != 1:
            return None
        product = data.get("product") or {}
        return _to_food(product, fallback_id=barcode)

    async def search(
        self, query: str, page: int = 1, page_size: int = 20
    ) -> tuple[list[Food], int]:
        params = {
            "search_terms": query,
            "json": 1,
            "page": page,
            "page_size": page_size,
            "fields": ",".join(
                [
                    "code",
                    "product_name",
                    "product_name_en",
                    "generic_name",
                    "brands",
                    "image_front_url",
                    "image_url",
                    "serving_size",
                    "nutriments",
                ]
            ),
        }
        try:
            resp = await self._client.get("/cgi/search.pl", params=params)
        except httpx.HTTPError as exc:
            raise OpenFoodFactsError(f"upstream error: {exc}") from exc
        if resp.status_code >= 500:
            raise OpenFoodFactsError(f"upstream {resp.status_code}")
        data = resp.json()
        products = data.get("products") or []
        items: list[Food] = []
        for idx, product in enumerate(products):
            food = _to_food(product, fallback_id=f"{query}:{idx}")
            if food is not None:
                items.append(food)
        total = int(data.get("count", len(items)))
        return items, total
