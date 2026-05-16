# syntax=docker/dockerfile:1.7
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# Install deps first for better layer caching.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Then copy app code.
COPY app ./app

# Run as a non-root user.
RUN useradd --create-home --shell /bin/bash app && chown -R app:app /app
USER app

# Render/Fly/Railway inject $PORT. Default to 8000 for local Docker runs.
ENV PORT=8000
EXPOSE 8000

# Use shell form so $PORT is interpolated at container runtime.
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
