from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class LoginRequest(BaseModel):
    email: str
    password: str = Field(min_length=8)


class UserCreate(BaseModel):
    email: str
    password: str = Field(min_length=8)
    full_name: str | None = None
    role_id: str | None = None


class UserResponse(BaseModel):
    id: str
    email: str
    full_name: str | None = None
    role_id: str | None = None
    is_active: bool = True
    created_at: datetime | None = None

    model_config = ConfigDict(extra="ignore")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse


class RefreshRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=8)


class ResourcePayload(BaseModel):
    data: dict[str, Any] = Field(default_factory=dict)


class ActionPayload(BaseModel):
    note: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)