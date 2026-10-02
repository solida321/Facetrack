from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password, verify_password
from app.models.role import Role
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest


def register_user(db: Session, request: RegisterRequest) -> User:
    """Creates a new employee account. Deliberately hardcoded to the
    'employee' role and 'pending_approval' status — this endpoint has
    no way to create an admin or manager account, on purpose.
    """
    existing = db.query(User).filter(User.email == request.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists.",
        )

    employee_role = db.query(Role).filter(Role.name == "employee").first()
    if not employee_role:
        # This means the roles table hasn't been seeded yet — a setup
        # problem, not something a real user caused.
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Employee role not found — seed the roles table first.",
        )

    user = User(
        full_name=request.full_name,
        email=request.email,
        password_hash=hash_password(request.password),
        external_id=request.external_id,
        role_id=employee_role.id,
        status="pending_approval",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def login_user(db: Session, request: LoginRequest) -> str:
    """Verifies credentials and returns a JWT. Raises 401 for wrong
    credentials AND for a not-yet-approved or inactive account — same
    error either way, so a login attempt can't be used to figure out
    which accounts exist or what their status is.
    """
    user = db.query(User).filter(User.email == request.email).first()

    if not user or not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    if user.status != "active":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    role = db.query(Role).filter(Role.id == user.role_id).first()
    return create_access_token(user_id=user.id, role_name=role.name)