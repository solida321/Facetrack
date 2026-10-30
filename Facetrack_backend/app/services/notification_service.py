# app/services/notification_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.notification import Notification
from app.models.role import Role
from app.models.user import User
from app.schemas.notification import NotificationCreate
from sqlalchemy import func


def create_notification(db: Session, data: NotificationCreate) -> Notification:
    """Called internally by other services (attendance, leave, correction) —
    not typically exposed as a public 'create' endpoint for end users."""
    notification = Notification(
        user_id=data.user_id,
        title=data.title,
        message=data.message,
        type=data.type,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification


def get_notifications_by_user(db: Session, user_id: int) -> list[Notification]:
    return db.query(Notification).filter(Notification.user_id == user_id).order_by(Notification.created_at.desc()).all()


def mark_as_read(db: Session, notification_id: int, user_id: int) -> Notification:
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    # Someone else's notification is reported as "not found" so ids can't be probed.
    if not notification or notification.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification


def notify(db: Session, user_id: int, title: str, message: str, type: str) -> None:
    """Adds one notification to the session. The caller commits, so the
    notification is saved in the same transaction as the thing it talks about."""
    db.add(Notification(user_id=user_id, title=title, message=message, type=type))


def approver_ids_for(db: Session, person: User) -> list[int]:
    """Who must review this person's requests: active managers in the same
    team. If there is no manager (or no team), every active admin."""
    ids: list[int] = []
    if person.group_id is not None:
        rows = (
            db.query(User.id)
            .join(Role, User.role_id == Role.id)
            .filter(User.group_id == person.group_id, User.status == "active",
                    Role.name == "manager", User.id != person.id)
            .all()
        )
        ids = [r[0] for r in rows]
    if not ids:
        rows = (
            db.query(User.id)
            .join(Role, User.role_id == Role.id)
            .filter(User.status == "active", Role.name == "admin", User.id != person.id)
            .all()
        )
        ids = [r[0] for r in rows]
    return ids

def admin_ids_for(db: Session, person: User) -> list[int]:
    """Every active admin (except the person themselves). Upper or lower case does not matter."""
    rows = (
        db.query(User.id)
        .join(Role, User.role_id == Role.id)
        .filter(
            func.lower(User.status) == "active",
            func.lower(Role.name) == "admin",
            User.id != person.id,
        )
        .all()
    )
    return [r[0] for r in rows] 



def notify_approvers(db: Session, person: User, title: str, message: str, type: str) -> None:
    # The team's manager reviews first, but admins can review everything,
    # so they are always told too. A set removes duplicates.
    ids = set(approver_ids_for(db, person)) | set(admin_ids_for(db, person))
    for uid in ids:
        notify(db, uid, title, message, type)

def count_unread(db: Session, user_id: int) -> int:
    return db.query(Notification).filter(
        Notification.user_id == user_id, Notification.is_read.is_(False)
    ).count()



def mark_all_read(db: Session, user_id: int) -> int:
    changed = db.query(Notification).filter(
        Notification.user_id == user_id, Notification.is_read.is_(False)
    ).update({"is_read": True})
    db.commit()
    return changed