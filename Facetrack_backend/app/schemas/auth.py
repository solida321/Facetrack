from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    """What the client must send to POST /api/auth/register.
    Role always defaults to employee and status to pending_approval —
    nobody can register themselves as an admin through this endpoint.
    """
    full_name: str
    email: EmailStr
    password: str
    external_id: str | None = None


class LoginRequest(BaseModel):
    """What the client must send to POST /api/auth/login."""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """What both register and login send back on success."""
    access_token: str
    token_type: str = "bearer"