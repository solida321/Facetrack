from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    """The 'ID badge reader' every protected endpoint goes through.

    Reads the token, proves it is genuine, loads the user from the database.
    The role is read from the database row (not from the token), so if an
    admin changes someone's role or deactivates them, it takes effect on the
    very next request instead of waiting for the token to expire.
    """
    try:
        payload = decode_access_token(token)
        user_id = int(payload.get("sub"))
    except (JWTError, TypeError, ValueError):
        # Bad signature, expired, or malformed token -> 401, not a 500 crash.
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    if user.status != "active":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Your account is not active")

    return user


def require_roles(*allowed_roles: str):
    """Builds a 'door lock' for an endpoint.

        @router.post("/", dependencies=[Depends(require_roles("admin"))])

    Anyone not holding one of the listed roles gets 403 Forbidden.
    (401 = "who are you?", 403 = "I know who you are, and the answer is no".)
    """

    def checker(current_user: User = Depends(get_current_user)) -> User:
        role_name = current_user.role.name if current_user.role else None
        if role_name not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to do this",
            )
        return current_user

    return checker


require_admin = require_roles("admin")
require_staff = require_roles("admin", "manager")
