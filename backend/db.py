from collections.abc import Mapping
from typing import Any

import httpx

from backend.config import get_settings


class RepositoryError(RuntimeError):
    """A database request failed or the database is not configured."""


class SupabaseRepository:
    def __init__(self) -> None:
        settings = get_settings()
        if not settings.supabase_configured:
            raise RepositoryError(
                "Supabase is not configured. Set SUPABASE_URL and "
                "SUPABASE_SERVICE_ROLE_KEY."
            )
        self.base_url = settings.supabase_url.rstrip("/") + "/rest/v1"
        self.headers = {
            "apikey": settings.supabase_service_role_key,
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
            "Content-Type": "application/json",
        }

    async def select(
        self,
        table: str,
        *,
        filters: Mapping[str, Any] | None = None,
        limit: int | None = None,
        order: str = "created_at.desc",
    ) -> list[dict[str, Any]]:
        params: dict[str, str] = {}
        for key, value in (filters or {}).items():
            params[key] = "is.null" if value is None else f"eq.{value}"
        if order:
            params["order"] = order
        if limit:
            params["limit"] = str(limit)
        return await self._request("GET", f"/{table}", params=params)

    async def insert(self, table: str, payload: Mapping[str, Any]) -> dict[str, Any]:
        rows = await self._request(
            "POST",
            f"/{table}",
            json=dict(payload),
            headers={"Prefer": "return=representation"},
        )
        return rows[0] if rows else {}

    async def update(
        self,
        table: str,
        record_id: str,
        payload: Mapping[str, Any],
    ) -> dict[str, Any]:
        rows = await self._request(
            "PATCH",
            f"/{table}",
            params={"id": f"eq.{record_id}"},
            json=dict(payload),
            headers={"Prefer": "return=representation"},
        )
        if not rows:
            raise RepositoryError("Record was not found.")
        return rows[0]

    async def delete(self, table: str, record_id: str) -> None:
        await self._request("DELETE", f"/{table}", params={"id": f"eq.{record_id}"})

    async def _request(
        self,
        method: str,
        path: str,
        *,
        params: dict[str, str] | None = None,
        json: Any = None,
        headers: dict[str, str] | None = None,
    ) -> list[dict[str, Any]]:
        request_headers = {**self.headers, **(headers or {})}
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.request(
                method,
                self.base_url + path,
                params=params,
                json=json,
                headers=request_headers,
            )
        if response.is_error:
            detail = response.text[:500]
            raise RepositoryError(f"Supabase request failed ({response.status_code}): {detail}")
        if not response.content:
            return []
        body = response.json()
        return body if isinstance(body, list) else [body]