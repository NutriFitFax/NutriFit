import httpx
import pytest
import respx


@pytest.mark.asyncio
async def test_barcode_hit(client: httpx.AsyncClient):
    payload = {
        "status": 1,
        "product": {
            "code": "5449000000996",
            "product_name": "Coca-Cola",
            "brands": "Coca-Cola, Coke",
            "image_front_url": "https://example.test/coke.png",
            "serving_size": "330 ml",
            "nutriments": {
                "energy-kcal_100g": 42,
                "proteins_100g": 0,
                "carbohydrates_100g": 10.6,
                "fat_100g": 0,
                "sugars_100g": 10.6,
                "salt_100g": 0,
            },
        },
    }
    with respx.mock(base_url="https://world.openfoodfacts.org") as router:
        router.get("/api/v2/product/5449000000996.json").respond(200, json=payload)
        resp = await client.get("/barcode/5449000000996")
    assert resp.status_code == 200
    body = resp.json()
    assert body["id"] == "5449000000996"
    assert body["name"] == "Coca-Cola"
    assert body["brand"] == "Coca-Cola"
    assert body["serving_size_g"] == 330.0
    assert body["macros_per_100g"]["calories_kcal"] == 42
    assert body["macros_per_100g"]["sugar_g"] == 10.6


@pytest.mark.asyncio
async def test_barcode_miss(client: httpx.AsyncClient):
    with respx.mock(base_url="https://world.openfoodfacts.org") as router:
        router.get("/api/v2/product/0000000000000.json").respond(
            200, json={"status": 0, "status_verbose": "no matching product"}
        )
        resp = await client.get("/barcode/0000000000000")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_barcode_invalid(client: httpx.AsyncClient):
    resp = await client.get("/barcode/abc")
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_barcode_upstream_5xx(client: httpx.AsyncClient):
    with respx.mock(base_url="https://world.openfoodfacts.org") as router:
        router.get("/api/v2/product/5449000000996.json").respond(503)
        resp = await client.get("/barcode/5449000000996")
    assert resp.status_code == 502
