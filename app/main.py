import ipaddress
import os
from datetime import datetime, timezone

import psycopg
import requests
from fastapi import FastAPI, HTTPException, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = FastAPI(title="IP Country API")
lookup_counter = Counter("ipgeo_lookup_total", "IP lookup requests", ["status"])


def database_config() -> dict[str, str | int]:
    return {
        "host": os.getenv(
            "DB_HOST",
            "postgres-rw.database.svc.cluster.local",
        ),
        "port": int(os.getenv("DB_PORT", "5432")),
        "dbname": os.getenv("DB_NAME", "ipgeo"),
        "user": os.getenv("DB_USER", "app"),
        "password": os.getenv("DB_PASSWORD", ""),
        "connect_timeout": 5,
    }


def create_table() -> None:
    with psycopg.connect(**database_config()) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS lookups (
                    id BIGSERIAL PRIMARY KEY,
                    ip_address INET NOT NULL,
                    country TEXT NOT NULL,
                    country_code TEXT,
                    created_at TIMESTAMPTZ NOT NULL
                )
                """
            )


@app.on_event("startup")
def startup() -> None:
    create_table()


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/lookup/{ip_address}")
def lookup(ip_address: str) -> dict:
    try:
        ipaddress.ip_address(ip_address)
    except ValueError as exc:
        lookup_counter.labels(status="invalid").inc()
        raise HTTPException(status_code=400, detail="Invalid IP address") from exc

    try:
        api_response = requests.get(f"https://ipwho.is/{ip_address}", timeout=5)
        api_response.raise_for_status()
        data = api_response.json()
        if not data.get("success", True):
            raise ValueError(data.get("message", "Lookup failed"))

        country = data.get("country") or "Unknown"
        country_code = data.get("country_code")
        created_at = datetime.now(timezone.utc)

        with psycopg.connect(**database_config()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO lookups (ip_address, country, country_code, created_at)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (ip_address, country, country_code, created_at),
                )

        lookup_counter.labels(status="success").inc()
        return {
            "ip": ip_address,
            "country": country,
            "country_code": country_code,
        }
    except (requests.RequestException, psycopg.Error, ValueError) as exc:
        lookup_counter.labels(status="error").inc()
        raise HTTPException(status_code=502, detail=str(exc)) from exc
