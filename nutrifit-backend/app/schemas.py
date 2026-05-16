"""Pydantic models for request and response bodies.

These are the contract between the Flutter app and the backend. Keep them
stable; breaking changes here mean changes in mobile/lib/api/api_client.dart.
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class Macros(BaseModel):
    """Macronutrients per 100 g (or per 100 ml for liquids)."""

    calories_kcal: float = Field(..., ge=0, description="Energy in kcal per 100 g/ml")
    protein_g: float = Field(..., ge=0)
    carbs_g: float = Field(..., ge=0)
    fat_g: float = Field(..., ge=0)
    fiber_g: float | None = Field(None, ge=0)
    sugar_g: float | None = Field(None, ge=0)
    salt_g: float | None = Field(None, ge=0)


class Food(BaseModel):
    """A single food item returned by barcode or search."""

    id: str = Field(..., description="Stable id (barcode for OFF products)")
    name: str
    brand: str | None = None
    image_url: str | None = None
    serving_size_g: float | None = Field(
        None, ge=0, description="Suggested serving size in grams"
    )
    macros_per_100g: Macros


class SearchResult(BaseModel):
    query: str
    page: int = Field(1, ge=1)
    page_size: int = Field(20, ge=1, le=50)
    total: int = Field(..., ge=0)
    items: list[Food]


class EstimatedFood(BaseModel):
    """One identified item in a meal photo."""

    name: str
    estimated_grams: float = Field(..., ge=0)
    confidence: float = Field(..., ge=0, le=1)
    macros_per_100g: Macros


class MealEstimate(BaseModel):
    items: list[EstimatedFood]
    total_calories_kcal: float = Field(..., ge=0)
    total_protein_g: float = Field(..., ge=0)
    total_carbs_g: float = Field(..., ge=0)
    total_fat_g: float = Field(..., ge=0)
    source: str = Field(..., description="'ai' when AI model used, 'stub' otherwise")
    notes: str | None = None


class HealthResponse(BaseModel):
    status: str = "ok"
    environment: str
    version: str
