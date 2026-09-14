from datetime import datetime, timedelta, timezone
from typing import Annotated, Any

import jwt
from fastapi import APIRouter, Depends, HTTPException, status

from backend.config import get_settings
from backend.db import RepositoryError, SupabaseRepository
from backend.dependencies import current_claims, get_repository
from backend.schemas import (
    ForgotPasswordRequest,
    LoginRequest,
    RefreshRequest,
    ResetPasswordRequest,
    TokenResponse,
    UserCreate,
    UserResponse,
)
from backend.security import (
    create_token,
    decode_token,
    hash_password,
    new_opaque_token,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


def _public_user(user: dict[str, Any]) -> UserResponse:
    return UserResponse(
        id=str(user["id"]),
        email=user["email"],
        full_name=user.get("full_name"),
        role_id=user.get("role_id"),
        is_active=user.get("is_active", True),
        created_at=user.get("created_at"),
    )


async def _issue_tokens(repo: SupabaseRepository, user: dict[str, Any]) -> TokenResponse:
    settings = get_settings()
    access = create_token(
        str(user["id"]),
        "access",
        timedelta(minutes=settings.access_token_minutes),
    )
    refresh = create_token(
        str(user["id"]),
        "refresh",
        timedelta(days=settings.refresh_token_days),
    )
    await repo.insert(
        "refresh_tokens",
        {
            "user_id": user["id"],
            "token_jti": decode_token(refresh, expected_type="refresh")["jti"],
            "expires_at": (
                datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_days)
            ).isoformat(),
        },
    )
    return TokenResponse(
        access_token=access,
        refresh_token=refresh,
        expires_in=settings.access_token_minutes * 60,
        user=_public_user(user),
    )


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest, repo: Annotated[SupabaseRepository, Depends(get_repository)]):
    try:
        users = await repo.select("users", filters={"email": payload.email.lower()}, limit=1)
    except RepositoryError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    user = users[0] if users else None
    if not user or not user.get("is_active", True) or not verify_password(
        payload.password, user.get("password_hash", "")
    ):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password.")
    return await _issue_tokens(repo, user)


@router.post("/logout")
async def logout(
    claims: Annotated[dict[str, Any], Depends(current_claims)],
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    user_id = claims.get("sub")
    await repo.update("users", str(user_id), {"last_logout_at": datetime.now(timezone.utc).isoformat()})
    return {"message": "Logged out successfully."}


@router.post("/refresh-token", response_model=TokenResponse)
async def refresh_token(
    payload: RefreshRequest,
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    try:
        claims = decode_token(payload.refresh_token, expected_type="refresh")
        users = await repo.select("users", filters={"id": claims["sub"]}, limit=1)
    except (jwt.InvalidTokenError, RuntimeError) as exc:
        raise HTTPException(status_code=401, detail="The refresh token is invalid or expired.") from exc
    if not users or not users[0].get("is_active", True):
        raise HTTPException(status_code=401, detail="The user is not active.")
    return await _issue_tokens(repo, users[0])


@router.post("/forgot-password")
async def forgot_password(
    payload: ForgotPasswordRequest,
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    users = await repo.select("users", filters={"email": payload.email.lower()}, limit=1)
    response: dict[str, Any] = {
        "message": "If an account exists for that email, reset instructions have been queued."
    }
    if users:
        settings = get_settings()
        token = new_opaque_token()
        await repo.insert(
            "password_resets",
            {
                "user_id": users[0]["id"],
                "token_hash": hash_password(token),
                "expires_at": (
                    datetime.now(timezone.utc) + timedelta(minutes=settings.password_reset_minutes)
                ).isoformat(),
            },
        )
        if settings.debug or settings.app_env != "production":
            response["development_reset_token"] = token
    return response


@router.post("/reset-password")
async def reset_password(
    payload: ResetPasswordRequest,
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    resets = await repo.select("password_resets", filters={"used_at": None}, limit=100)
    matching = next(
        (
            reset
            for reset in resets
            if verify_password(payload.token, reset.get("token_hash", ""))
            and datetime.fromisoformat(reset["expires_at"].replace("Z", "+00:00")) > datetime.now(timezone.utc)
        ),
        None,
    )
    if not matching:
        raise HTTPException(status_code=400, detail="The password reset token is invalid or expired.")
    await repo.update("users", str(matching["user_id"]), {"password_hash": hash_password(payload.new_password)})
    await repo.update("password_resets", str(matching["id"]), {"used_at": datetime.now(timezone.utc).isoformat()})
    return {"message": "Password reset successfully."}


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(
    payload: UserCreate,
    repo: Annotated[SupabaseRepository, Depends(get_repository)],
):
    existing = await repo.select("users", filters={"email": payload.email.lower()}, limit=1)
    if existing:
        raise HTTPException(status_code=409, detail="An account with that email already exists.")
    user = await repo.insert(
        "users",
        {
            "email": payload.email.lower(),
            "password_hash": hash_password(payload.password),
            "full_name": payload.full_name,
            "role_id": payload.role_id,
        },
    )
    return _public_user(user)