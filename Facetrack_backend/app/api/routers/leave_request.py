# app/api/routers/leave_request.py
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from app.models.leave_request import LeaveRequest
from app.models.user import User
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_staff
from app.core.permissions import ensure_can_access_group, ensure_can_access_user, is_admin
from app.schemas.leave_request import LeaveRequestCreate, LeaveRequestReview, LeaveRequestOut
from app.services import leave_service
from app.services.audit_service import record_audit

router = APIRouter(prefix="/leave-requests", tags=["Leave Requests"])


@router.post("/", response_model=LeaveRequestOut)
def create_leave_request(
    data: LeaveRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # The requester is always the logged-in user (token), never a value from the URL.
    return leave_service.create_leave_request(db, current_user.id, data)


@router.get("/", response_model=list[LeaveRequestOut])
def list_leave_requests(db: Session = Depends(get_db), current_user: User = Depends(require_staff)):
    if is_admin(current_user):
        return leave_service.get_all_leave_requests(db)
    if current_user.group_id is None:
        return []
    return (
        db.query(LeaveRequest)
        .join(User, LeaveRequest.user_id == User.id)
        .filter(User.group_id == current_user.group_id)
        .all()
    )


@router.get("/user/{user_id}", response_model=list[LeaveRequestOut])
def get_leave_requests_by_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_can_access_user(db, current_user, user_id)
    return leave_service.get_leave_requests_by_user(db, user_id)


@router.get("/group/{group_id}", response_model=list[LeaveRequestOut])
def get_leave_requests_by_group(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    ensure_can_access_group(current_user, group_id)
    return (
        db.query(LeaveRequest)
        .join(User, LeaveRequest.user_id == User.id)
        .filter(User.group_id == group_id)
        .all()
    )


@router.get("/{leave_id}", response_model=LeaveRequestOut)
def get_leave_request(
    leave_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    leave = leave_service.get_leave_request(db, leave_id)
    ensure_can_access_user(db, current_user, leave.user_id)
    return leave


@router.put("/{leave_id}/review", response_model=LeaveRequestOut)
def review_leave_request(
    leave_id: int,
    data: LeaveRequestReview,
    request: Request,
    db: Session = Depends(get_db),
    reviewer: User = Depends(require_staff),
):
    leave = leave_service.get_leave_request(db, leave_id)
    if leave.user_id == reviewer.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You cannot review your own request")
    # A manager may only review people in their own group.
    ensure_can_access_user(db, reviewer, leave.user_id)

    result = leave_service.review_leave_request(db, leave_id, reviewer.id, data)
    record_audit(db, request, reviewer, "review", "leave_requests", leave_id, {"decision": data.status})
    return result
