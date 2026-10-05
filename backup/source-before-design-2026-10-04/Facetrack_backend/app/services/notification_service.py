# app/services/notification_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.notification import Notification
from app.schemas.notification import NotificationCreate


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


def mark_as_read(db: Session, notification_id: int) -> Notification:
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification