# Service Operations API

FastAPI backend for managing service customers, equipment, field work, inventory, billing, and operational reporting.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the FastAPI server
- `python -m compileall backend api` — check Python syntax
- `uv sync` — install Python dependencies from `pyproject.toml`
- Apply `supabase/migrations/001_initial_schema.sql` and `002_domain_tables.sql` in Supabase before using data endpoints
- Required env: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `JWT_SECRET`

## Stack

- Python 3.11, FastAPI, Uvicorn, Pydantic Settings
- Database: Supabase Postgres via the REST API
- Deployment: Vercel Python function at `api/index.py`
- Authentication: signed access/refresh tokens backed by Supabase user and token tables

## Where things live

- `backend/main.py` — FastAPI app and system endpoints
- `backend/routes/auth.py` — registration, login, refresh, logout, and password reset
- `backend/routes/resources.py` — protected operations collections and workflow actions
- `backend/db.py` — Supabase REST repository
- `supabase/migrations/001_initial_schema.sql` and `002_domain_tables.sql` — database source of truth
- `docs/vercel-environment.md` — Vercel setup and environment variables

## Architecture decisions

- Server calls Supabase through REST so the Vercel function stays lightweight and does not need a native database driver.
- The server-only service-role key is required for API access; it must never be shipped to a browser.
- Every API resource has a dedicated Supabase table; `resource_records` is reserved for flexible timeline and activity entries.

## Product

- Authenticated service operations API spanning customers, assets, service requests, job orders, technicians, inventory, projects, billing, reporting, and related workflow actions.

## User preferences

No additional user preferences recorded.

## Gotchas

- Apply the Supabase migration before testing protected endpoints.
- Keep `SUPABASE_SERVICE_ROLE_KEY` and `JWT_SECRET` in Vercel/Secrets only.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
