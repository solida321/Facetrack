from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    """What the client must send to POST /api/auth/register.
    Role always defaults to employee and status to pending_approval —
    nobody can register themselves as an admin through this endpoint.
    """
    full_name: str = Field(..., min_length=2, max_length=150)
    email: EmailStr
    # At least 8 characters. At most 72, because the password hashing (bcrypt) ignores the rest.
    password: str = Field(..., min_length=8, max_length=72)
    phone: str | None = Field(default=None, min_length=8, max_length=30, pattern=r"^[0-9+\- ]+$")
    external_id: str | None = Field(default=None, max_length=50)  # employee / student id


class LoginRequest(BaseModel):
    """What the client must send to POST /api/auth/login."""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """What both register and login send back on success."""
    access_token: str
    token_type: str = "bearer"