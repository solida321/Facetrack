from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse
from app.schemas.user import UserResponse
from app.services.auth_service import login_user, register_user

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse)
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    """Creates a pending_approval employee account. No token is returned
    here — the account can't do anything yet until an admin activates it,
    so there's nothing useful to log in to right away.
    """
    user = register_user(db, request)
    return user


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """The actual login endpoint — returns a JWT on success."""
    token = login_user(db, request)
    return TokenResponse(access_token=token)