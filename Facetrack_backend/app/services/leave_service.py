# app/services/leave_service.py
from datetime import datetime, timezone

from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.leave_request import LeaveRequest
from app.schemas.leave_request import LeaveRequestCreate, LeaveRequestReview
from app.models.notification import Notification


def create_leave_request(db: Session, user_id: int, data: LeaveRequestCreate) -> LeaveRequest:
    leave = LeaveRequest(
        user_id=user_id,
        date_from=data.date_from,
        date_to=data.date_to,
        reason=data.reason,
        status="pending",
    )
    db.add(leave)
    db.commit()
    db.refresh(leave)
    return leave


def get_leave_request(db: Session, leave_id: int) -> LeaveRequest:
    leave = db.query(LeaveRequest).filter(LeaveRequest.id == leave_id).first()
    if not leave:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave request not found")
    return leave


def get_leave_requests_by_user(db: Session, user_id: int) -> list[LeaveRequest]:
    return db.query(LeaveRequest).filter(LeaveRequest.user_id == user_id).all()


def get_all_leave_requests(db: Session) -> list[LeaveRequest]:
    return db.query(LeaveRequest).all()






def review_leave_request(db: Session, leave_id: int, reviewer_id: int, data: LeaveRequestReview) -> LeaveRequest:
    leave = get_leave_request(db, leave_id)
    if leave.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This request has already been reviewed")

    leave.status = data.status
    leave.reviewed_by = reviewer_id
    leave.reviewed_at = datetime.now(timezone.utc)

    db.add(Notification(
        user_id=leave.user_id,
        title=f"Leave request {data.status}",
        message=f"Your leave request from {leave.date_from} to {leave.date_to} was {data.status}.",
        type=f"leave_{data.status}",
    ))

    db.commit()
    db.refresh(leave)
    return leave