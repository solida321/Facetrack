# app/api/routers/notification.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.core.permissions import is_admin
from app.models.user import User
from app.schemas.notification import NotificationCreate, NotificationOut
from app.services import notification_service

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.post("/", response_model=NotificationOut)
def create_notification(
    data: NotificationCreate,
    db: Session = Depends(get_db),
    _admin: User = Depends(require_admin),
):
    return notification_service.create_notification(db, data)


@router.get("/user/{user_id}", response_model=list[NotificationOut])
def get_notifications_by_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only read your own notifications")
    return notification_service.get_notifications_by_user(db, user_id)


@router.get("/user/{user_id}/unread-count")
def unread_count(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only read your own notifications")
    return {"count": notification_service.count_unread(db, user_id)}


@router.put("/read-all")
def mark_all_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    changed = notification_service.mark_all_read(db, current_user.id)
    return {"updated": changed}


@router.put("/{notification_id}/read", response_model=NotificationOut)
def mark_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return notification_service.mark_as_read(db, notification_id, current_user.id)