# app/api/routers/notification.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.notification import NotificationCreate, NotificationOut
from app.services import notification_service

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.post("/", response_model=NotificationOut)
def create_notification(data: NotificationCreate, db: Session = Depends(get_db)):
    return notification_service.create_notification(db, data)


@router.get("/user/{user_id}", response_model=list[NotificationOut])
def get_notifications_by_user(user_id: int, db: Session = Depends(get_db)):
    return notification_service.get_notifications_by_user(db, user_id)


@router.put("/{notification_id}/read", response_model=NotificationOut)
def mark_as_read(notification_id: int, db: Session = Depends(get_db)):
    return notification_service.mark_as_read(db, notification_id)