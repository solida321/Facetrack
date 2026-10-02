from datetime import datetime
from pydantic import BaseModel


class UserResponse(BaseModel):
    """Used by POST /api/auth/register — the newly created account,
    before any role/group assignment context is needed.
    """
    id: int
    full_name: str
    email: str
    status: str

    class Config:
        from_attributes = True


class RoleOut(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True


class UserOut(BaseModel):
    """Used by GET /users/me — includes the nested role so the frontend
    can route by role name after login.
    """
    id: int
    full_name: str
    email: str
    phone: str | None
    gender: str | None
    group_id: int | None
    role: RoleOut
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    status: str | None = None
    role_id: int | None = None
    group_id: int | None = None
    full_name: str | None = None
    phone: str | None = None
    gender: str | None = None



class UserCreateByAdmin(BaseModel):
    full_name: str
    email: str
    password: str
    role_id: int
    group_id: int | None = None
    status: str = "active"