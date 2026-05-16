import httpx
import pytest


@pytest.mark.asyncio
async def test_health_ok(client: httpx.AsyncClient):
    resp = await client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert body["environment"] == "test"
    assert body["version"]


@pytest.mark.asyncio
async def test_root_ok(client: httpx.AsyncClient):
    resp = await client.get("/")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"
