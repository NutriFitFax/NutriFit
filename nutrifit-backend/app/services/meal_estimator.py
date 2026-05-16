"""Meal-image estimation.

If OPENAI_API_KEY is set we call OpenAI's vision-capable model and ask it to
return a JSON list of items. If not, we return a deterministic stub so the
mobile app has something to render during development without burning credits.

The stub keeps the schema honest: same shape, plausible numbers.
"""

from __future__ import annotations

import base64
import json

import httpx

from app.config import Settings
from app.schemas import EstimatedFood, Macros, MealEstimate


class MealEstimatorError(Exception):
    """Raised when the AI provider returns an unparseable response."""


_STUB_ITEMS: list[EstimatedFood] = [
    EstimatedFood(
        name="Grilled chicken breast",
        estimated_grams=150.0,
        confidence=0.6,
        macros_per_100g=Macros(
            calories_kcal=165, protein_g=31, carbs_g=0, fat_g=3.6
        ),
    ),
    EstimatedFood(
        name="Steamed rice",
        estimated_grams=180.0,
        confidence=0.55,
        macros_per_100g=Macros(
            calories_kcal=130, protein_g=2.7, carbs_g=28, fat_g=0.3
        ),
    ),
    EstimatedFood(
        name="Mixed vegetables",
        estimated_grams=90.0,
        confidence=0.5,
        macros_per_100g=Macros(
            calories_kcal=65, protein_g=2.5, carbs_g=13, fat_g=0.5
        ),
    ),
]


def _totals(items: list[EstimatedFood]) -> tuple[float, float, float, float]:
    cals = sum(i.macros_per_100g.calories_kcal * i.estimated_grams / 100 for i in items)
    prot = sum(i.macros_per_100g.protein_g * i.estimated_grams / 100 for i in items)
    carb = sum(i.macros_per_100g.carbs_g * i.estimated_grams / 100 for i in items)
    fat = sum(i.macros_per_100g.fat_g * i.estimated_grams / 100 for i in items)
    return round(cals, 1), round(prot, 1), round(carb, 1), round(fat, 1)


def _stub() -> MealEstimate:
    cals, prot, carb, fat = _totals(_STUB_ITEMS)
    return MealEstimate(
        items=_STUB_ITEMS,
        total_calories_kcal=cals,
        total_protein_g=prot,
        total_carbs_g=carb,
        total_fat_g=fat,
        source="stub",
        notes="OPENAI_API_KEY not set — returning deterministic stub estimate.",
    )


_PROMPT = (
    "You are a nutrition assistant. Identify the foods in this meal photo. "
    "Reply with ONLY valid JSON of this shape:\n"
    '{"items":[{"name":str,"estimated_grams":number,"confidence":number 0..1,'
    '"macros_per_100g":{"calories_kcal":number,"protein_g":number,'
    '"carbs_g":number,"fat_g":number}}]}\n'
    "If unsure, still return a best guess; never include prose outside JSON."
)


async def _call_openai(
    settings: Settings, image_bytes: bytes, content_type: str
) -> list[EstimatedFood]:
    b64 = base64.b64encode(image_bytes).decode("ascii")
    payload = {
        "model": settings.openai_model,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _PROMPT},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{content_type};base64,{b64}"},
                    },
                ],
            }
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.2,
    }
    headers = {
        "Authorization": f"Bearer {settings.openai_api_key}",
        "Content-Type": "application/json",
    }
    async with httpx.AsyncClient(timeout=settings.http_timeout * 4) as client:
        resp = await client.post(
            "https://api.openai.com/v1/chat/completions",
            json=payload,
            headers=headers,
        )
    if resp.status_code >= 400:
        raise MealEstimatorError(f"openai {resp.status_code}: {resp.text[:200]}")
    body = resp.json()
    try:
        content = body["choices"][0]["message"]["content"]
        parsed = json.loads(content)
        raw_items = parsed["items"]
    except (KeyError, IndexError, json.JSONDecodeError) as exc:
        raise MealEstimatorError(f"bad openai response: {exc}") from exc
    items: list[EstimatedFood] = []
    for raw in raw_items:
        try:
            items.append(EstimatedFood(**raw))
        except Exception:
            continue
    if not items:
        raise MealEstimatorError("no parseable items in openai response")
    return items


async def estimate(
    settings: Settings, image_bytes: bytes, content_type: str | None
) -> MealEstimate:
    if not settings.openai_api_key:
        return _stub()
    ctype = content_type or "image/jpeg"
    items = await _call_openai(settings, image_bytes, ctype)
    cals, prot, carb, fat = _totals(items)
    return MealEstimate(
        items=items,
        total_calories_kcal=cals,
        total_protein_g=prot,
        total_carbs_g=carb,
        total_fat_g=fat,
        source="ai",
    )
