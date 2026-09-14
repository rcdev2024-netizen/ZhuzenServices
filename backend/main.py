from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.config import get_settings
from backend.routes.auth import router as auth_router
from backend.routes.catalog import router as catalog_router
from backend.routes.resources import router as resources_router


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    yield


settings = get_settings()
app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Service operations API for customers, assets, service delivery, inventory, billing, and reporting.",
    lifespan=lifespan,
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins,
    allow_credentials=settings.cors_origins.strip() != "*",
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/healthz", tags=["System"])
async def health() -> JSONResponse:
    return JSONResponse(
        {
            "status": "ok",
            "service": settings.app_name,
            "environment": settings.app_env,
            "supabase_configured": settings.supabase_configured,
        }
    )


@app.get("/", tags=["System"])
async def root() -> dict[str, str]:
    return {"service": settings.app_name, "docs": "/docs", "health": "/api/healthz"}


app.include_router(auth_router, prefix=settings.api_prefix)
app.include_router(catalog_router)
app.include_router(resources_router, prefix=settings.api_prefix)