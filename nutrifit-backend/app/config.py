"""Runtime configuration loaded from environment variables."""

from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache


def _csv(value: str | None) -> list[str]:
    if not value:
        return []
    return [part.strip() for part in value.split(",") if part.strip()]


@dataclass(frozen=True)
class Settings:
    app_name: str = "NutriFit Backend"
    environment: str = "development"
    # Comma-separated list. Use ["*"] for any origin (dev only).
    cors_origins: tuple[str, ...] = ("*",)
    # OpenFoodFacts API base. Overridable for tests.
    openfoodfacts_base_url: str = "https://world.openfoodfacts.org"
    # Outbound HTTP timeout (seconds).
    http_timeout: float = 8.0
    # Optional API key for AI-based meal image estimation.
    openai_api_key: str | None = None
    openai_model: str = "gpt-4o-mini"
    # Max upload size for /estimate-meal in bytes (default 8 MiB).
    max_upload_bytes: int = 8 * 1024 * 1024
    # User-Agent we send to OpenFoodFacts (required by their ToS).
    user_agent: str = "NutriFit/0.1 (student project; contact: teamwork@loveiq.org)"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    cors_env = os.getenv("CORS_ORIGINS")
    cors = tuple(_csv(cors_env)) if cors_env else ("*",)
    return Settings(
        environment=os.getenv("ENVIRONMENT", "development"),
        cors_origins=cors,
        openfoodfacts_base_url=os.getenv(
            "OPENFOODFACTS_BASE_URL", "https://world.openfoodfacts.org"
        ),
        http_timeout=float(os.getenv("HTTP_TIMEOUT", "8.0")),
        openai_api_key=os.getenv("OPENAI_API_KEY") or None,
        openai_model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        max_upload_bytes=int(os.getenv("MAX_UPLOAD_BYTES", str(8 * 1024 * 1024))),
        user_agent=os.getenv(
            "HTTP_USER_AGENT",
            "NutriFit/0.1 (student project; contact: teamwork@loveiq.org)",
        ),
    )
