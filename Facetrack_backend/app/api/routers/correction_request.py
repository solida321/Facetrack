# app/api/routers/correction_request.py
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from app.models.correction_request import CorrectionRequest
from app.models.attendance_record import AttendanceRecord
from app.models.user import User
from app.core.database import get_db
from app.core.dependencies import get_current_user, require_staff
from app.core.permissions import ensure_can_access_group, ensure_can_access_user, is_admin
from app.schemas.correction_request import CorrectionRequestCreate, CorrectionRequestReview, CorrectionRequestOut
from app.services import correction_service
from app.services.audit_service import record_audit

router = APIRouter(prefix="/correction-requests", tags=["Correction Requests"])


@router.post("/", response_model=CorrectionRequestOut)
def create_correction_request(
    data: CorrectionRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # The requester is always the logged-in user (token), never a value from the URL.
    return correction_service.create_correction_request(db, current_user.id, data)


@router.get("/", response_model=list[CorrectionRequestOut])
def list_correction_requests(db: Session = Depends(get_db), current_user: User = Depends(require_staff)):
    if is_admin(current_user):
        return correction_service.get_all_correction_requests(db)
    if current_user.group_id is None:
        return []
    return (
        db.query(CorrectionRequest)
        .join(AttendanceRecord, CorrectionRequest.attendance_record_id == AttendanceRecord.id)
        .join(User, AttendanceRecord.user_id == User.id)
        .filter(User.group_id == current_user.group_id)
        .all()
    )


@router.get("/user/{user_id}", response_model=list[CorrectionRequestOut])
def get_correction_requests_by_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_can_access_user(db, current_user, user_id)
    return correction_service.get_correction_requests_by_user(db, user_id)


@router.get("/group/{group_id}", response_model=list[CorrectionRequestOut])
def get_correction_requests_by_group(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    ensure_can_access_group(current_user, group_id)
    return (
        db.query(CorrectionRequest)
        .join(AttendanceRecord, CorrectionRequest.attendance_record_id == AttendanceRecord.id)
        .join(User, AttendanceRecord.user_id == User.id)
        .filter(User.group_id == group_id)
        .all()
    )


@router.get("/{correction_id}", response_model=CorrectionRequestOut)
def get_correction_request(
    correction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    correction = correction_service.get_correction_request(db, correction_id)
    ensure_can_access_user(db, current_user, correction.requested_by)
    return correction


@router.put("/{correction_id}/review", response_model=CorrectionRequestOut)
def review_correction_request(
    correction_id: int,
    data: CorrectionRequestReview,
    request: Request,
    db: Session = Depends(get_db),
    reviewer: User = Depends(require_staff),
):
    correction = correction_service.get_correction_request(db, correction_id)
    if correction.requested_by == reviewer.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You cannot review your own request")
    # A manager may only review people in their own group.
    ensure_can_access_user(db, reviewer, correction.requested_by)

    result = correction_service.review_correction_request(db, correction_id, reviewer.id, data)
    record_audit(db, request, reviewer, "review", "correction_requests", correction_id, {"decision": data.status})
    return result
