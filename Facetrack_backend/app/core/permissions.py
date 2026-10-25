"""Small helpers for "is this person allowed to see/touch THAT person's data?".

require_roles() answers "what kind of user are you?".
These helpers answer the second question: "is this record yours (or your team's)?"

Rules used across the app:
  admin    -> everything
  manager  -> their own data + data of people in their own group
  employee -> their own data only
"""
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User


def role_name(user: User) -> str | None:
    return user.role.name if user.role else None


def is_admin(user: User) -> bool:
    return role_name(user) == "admin"


def is_manager(user: User) -> bool:
    return role_name(user) == "manager"


def can_access_user(db: Session, actor: User, target_user_id: int) -> bool:
    if actor.id == target_user_id or is_admin(actor):
        return True
    if is_manager(actor) and actor.group_id is not None:
        target = db.query(User).filter(User.id == target_user_id).first()
        return target is not None and target.group_id == actor.group_id
    return False


def ensure_can_access_user(db: Session, actor: User, target_user_id: int) -> None:
    if not can_access_user(db, actor, target_user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access this data",
        )


def ensure_can_access_group(actor: User, group_id: int) -> None:
    """Admin: any group. Everyone else: only their own group."""
    if is_admin(actor):
        return
    if actor.group_id is None or actor.group_id != group_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access this group",
        )
