from datetime import datetime, timedelta, timezone

from jose import jwt
from passlib.context import CryptContext

from app.core.config import settings

# bcrypt is the standard, well-tested choice for password hashing —
# this object is reused everywhere passwords are hashed or checked.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain_password: str) -> str:
    """Called once, at registration — turns a typed password into the
    string that actually gets stored in users.password_hash. The plain
    password itself is never stored anywhere.
    """
    return pwd_context.hash(plain_password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Called at login — checks a typed password against the stored hash.
    Note there's no way to reverse a hash back into the original password;
    this only confirms the two would have produced the same hash.
    """
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(user_id: int, role_name: str) -> str:
    """Builds the actual JWT handed back on successful login. `sub` (subject)
    and `role` are the two pieces of info later endpoints will read back out
    of the token via get_current_user() — no separate database lookup needed
    just to know who's making a request.
    """
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {"sub": str(user_id), "role": role_name, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> dict:
    """Reverses create_access_token — verifies the signature (proving it was
    genuinely issued by this server and not forged) and returns the payload.
    Raises a jose.JWTError if the token is invalid or expired; the router
    layer (api/deps.py, built next) will catch that and return a 401.
    """
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])