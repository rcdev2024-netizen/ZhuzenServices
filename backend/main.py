from contextlib import asynccontextmanager
import logging
from typing import AsyncIterator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from backend.config import get_settings
from backend.routes.auth import router as auth_router
from backend.routes.resources import router as resources_router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    logger.info("Application startup")
    yield
    logger.info("Application shutdown")


# Rate limiting middleware
from collections import defaultdict
from datetime import datetime, timedelta

rate_limits = defaultdict(list)
RATE_LIMIT_REQUESTS = 100
RATE_LIMIT_WINDOW = 60  # seconds


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        # Get client IP
        client_ip = request.client.host if request.client else "unknown"
        
        # Check rate limit for auth endpoints (stricter)
        if request.url.path.startswith("/api/auth/"):
            limit = 10
            window = 60
        else:
            limit = RATE_LIMIT_REQUESTS
            window = RATE_LIMIT_WINDOW
        
        now = datetime.now()
        # Clean old requests
        rate_limits[client_ip] = [
            req_time for req_time in rate_limits[client_ip]
            if now - req_time < timedelta(seconds=window)
        ]
        
        if len(rate_limits[client_ip]) >= limit:
            logger.warning(f"Rate limit exceeded for {client_ip}")
            return Response("Too Many Requests", status_code=429)
        
        rate_limits[client_ip].append(now)
        response = await call_next(request)
        return response


settings = get_settings()
app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Service operations API for customers, assets, service delivery, inventory, billing, and reporting.",
    lifespan=lifespan,
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
)

# Middleware stack (order matters)
app.add_middleware(RateLimitMiddleware)

# Browsers do not allow `Access-Control-Allow-Origin: *` together with
# credentials. In allow-all mode, match every origin and let Starlette echo
# the request's origin instead. This keeps browser preflight and credentialed
# requests working for any frontend origin.
cors_allow_all = settings.cors_allow_all
app.add_middleware(
    CORSMiddleware,
    allow_origins=[] if cors_allow_all else settings.origins,
    allow_origin_regex=r".*" if cors_allow_all else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info(f"Starting {settings.app_name} in {settings.app_env} environment")
logger.debug(f"CORS origins: {settings.origins}")
logger.debug(f"API prefix: {settings.api_prefix}")


@app.get("/api/healthz", tags=["System"])
async def health() -> JSONResponse:
    logger.info("Health check requested")
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
app.include_router(resources_router, prefix=settings.api_prefix)