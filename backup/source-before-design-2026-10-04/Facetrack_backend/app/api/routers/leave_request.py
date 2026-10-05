# app/api/routers/leave_request.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models.leave_request import LeaveRequest
from app.core.database import get_db
from app.schemas.leave_request import LeaveRequestCreate, LeaveRequestReview, LeaveRequestOut
from app.services import leave_service

router = APIRouter(prefix="/leave-requests", tags=["Leave Requests"])


@router.post("/", response_model=LeaveRequestOut)
def create_leave_request(user_id: int, data: LeaveRequestCreate, db: Session = Depends(get_db)):
    return leave_service.create_leave_request(db, user_id, data)


@router.get("/", response_model=list[LeaveRequestOut])
def list_leave_requests(db: Session = Depends(get_db)):
    return leave_service.get_all_leave_requests(db)


@router.get("/user/{user_id}", response_model=list[LeaveRequestOut])
def get_leave_requests_by_user(user_id: int, db: Session = Depends(get_db)):
    return leave_service.get_leave_requests_by_user(db, user_id)


@router.get("/group/{group_id}", response_model=list[LeaveRequestOut])
def get_leave_requests_by_group(group_id: int, db: Session = Depends(get_db)):
    from app.models.user import User
    return (
        db.query(LeaveRequest)
        .join(User, LeaveRequest.user_id == User.id)
        .filter(User.group_id == group_id)
        .all()
    )


@router.get("/{leave_id}", response_model=LeaveRequestOut)
def get_leave_request(leave_id: int, db: Session = Depends(get_db)):
    return leave_service.get_leave_request(db, leave_id)


@router.put("/{leave_id}/review", response_model=LeaveRequestOut)
def review_leave_request(leave_id: int, reviewer_id: int, data: LeaveRequestReview, db: Session = Depends(get_db)):
    return leave_service.review_leave_request(db, leave_id, reviewer_id, data)