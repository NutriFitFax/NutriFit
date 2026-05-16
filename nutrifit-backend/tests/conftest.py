"""Shared pytest fixtures.

We use httpx.ASGITransport + AsyncClient to drive the FastAPI app in-process —
no live server, no port binding. Upstream OpenFoodFacts calls are mocked with
respx so tests are hermetic and offline-friendly.
"""

from __future__ import annotations

import os
from collections.abc import AsyncIterator

import httpx
import pytest

# Force a known env BEFORE the app imports its settings.
os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("CORS_ORIGINS", "*")
os.environ.pop("OPENAI_API_KEY", None)

from app.config import get_settings
from app.main import create_app


@pytest.fixture(autouse=True)
def _clear_settings_cache():
    """Each test gets a fresh Settings — env mutations don't leak."""
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture
async def client() -> AsyncIterator[httpx.AsyncClient]:
    app = create_app()
    transport = httpx.ASGITransport(app=app)
    async with (
        httpx.AsyncClient(transport=transport, base_url="http://test") as c,
        # Trigger startup so app.state.off_client is initialised.
        app.router.lifespan_context(app),
    ):
        yield c
