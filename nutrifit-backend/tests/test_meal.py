import io

import httpx
import pytest

# 1x1 PNG, smallest valid PNG image (67 bytes).
_TINY_PNG = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\rIDATx\x9cc\xf8\xcf"
    b"\xc0\x00\x00\x00\x03\x00\x01\xa7z\xcd\xdc\x00\x00\x00\x00IEND\xaeB`\x82"
)


@pytest.mark.asyncio
async def test_estimate_meal_stub(client: httpx.AsyncClient):
    files = {"image": ("meal.png", io.BytesIO(_TINY_PNG), "image/png")}
    resp = await client.post("/estimate-meal", files=files)
    assert resp.status_code == 200
    body = resp.json()
    assert body["source"] == "stub"
    assert len(body["items"]) >= 1
    assert body["total_calories_kcal"] > 0


@pytest.mark.asyncio
async def test_estimate_meal_rejects_non_image(client: httpx.AsyncClient):
    files = {"image": ("not.txt", io.BytesIO(b"hello"), "text/plain")}
    resp = await client.post("/estimate-meal", files=files)
    assert resp.status_code == 415


@pytest.mark.asyncio
async def test_estimate_meal_rejects_empty(client: httpx.AsyncClient):
    files = {"image": ("empty.png", io.BytesIO(b""), "image/png")}
    resp = await client.post("/estimate-meal", files=files)
    assert resp.status_code == 422
