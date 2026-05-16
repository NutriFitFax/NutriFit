import httpx
import pytest
import respx


@pytest.mark.asyncio
async def test_search_returns_items(client: httpx.AsyncClient):
    payload = {
        "count": 2,
        "products": [
            {
                "code": "1",
                "product_name": "Greek Yogurt",
                "brands": "BrandA",
                "nutriments": {
                    "energy-kcal_100g": 59,
                    "proteins_100g": 10,
                    "carbohydrates_100g": 3.6,
                    "fat_100g": 0.4,
                },
            },
            {
                "code": "2",
                "product_name": "",  # falls back to generic_name
                "generic_name": "Plain Yogurt",
                "nutriments": {
                    "energy-kcal_100g": 61,
                    "proteins_100g": 3.5,
                    "carbohydrates_100g": 4.7,
                    "fat_100g": 3.3,
                },
            },
        ],
    }
    with respx.mock(base_url="https://world.openfoodfacts.org") as router:
        router.get("/cgi/search.pl").respond(200, json=payload)
        resp = await client.get("/search", params={"q": "yogurt"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["query"] == "yogurt"
    assert body["total"] == 2
    assert len(body["items"]) == 2
    assert body["items"][0]["name"] == "Greek Yogurt"
    assert body["items"][1]["name"] == "Plain Yogurt"


@pytest.mark.asyncio
async def test_search_skips_nameless(client: httpx.AsyncClient):
    payload = {
        "count": 1,
        "products": [{"code": "x", "nutriments": {}}],
    }
    with respx.mock(base_url="https://world.openfoodfacts.org") as router:
        router.get("/cgi/search.pl").respond(200, json=payload)
        resp = await client.get("/search", params={"q": "nothing"})
    assert resp.status_code == 200
    assert resp.json()["items"] == []


@pytest.mark.asyncio
async def test_search_requires_q(client: httpx.AsyncClient):
    resp = await client.get("/search")
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_search_upstream_5xx(client: httpx.AsyncClient):
    with respx.mock(base_url="https://world.openfoodfacts.org") as router:
        router.get("/cgi/search.pl").respond(500)
        resp = await client.get("/search", params={"q": "x"})
    assert resp.status_code == 502
