from datetime import datetime
from typing import Literal
from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    role: str = "viewer"


class UserLogin(BaseModel):
    username: str
    password: str


class UserOut(BaseModel):
    id: int
    username: str
    email: str
    role: str
    company_id: int | None = None
    company_super_admin: bool = False
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    email: str | None = None
    role: str | None = None
    company_id: int | None = None
    company_super_admin: bool | None = None
    is_active: bool | None = None


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: int | None = None


class CompanyCreate(BaseModel):
    name: str
    industry: str | None = None


class CompanyJoin(BaseModel):
    company_id: int = Field(..., ge=100_000_000, le=999_999_999)


class CompanyOut(BaseModel):
    id: int
    name: str
    industry: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class CompanyMemberInvite(BaseModel):
    username: str | None = None
    email: EmailStr | None = None
    role: Literal["admin", "accountant", "viewer"] = "viewer"


class CompanySuperAdminTransfer(BaseModel):
    target_user_id: int


class CompanyMemberRoleUpdate(BaseModel):
    role: Literal["admin", "accountant", "viewer"]
