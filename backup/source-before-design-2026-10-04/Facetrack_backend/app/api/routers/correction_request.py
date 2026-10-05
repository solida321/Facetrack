# app/api/routers/correction_request.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models.correction_request import CorrectionRequest
from app.core.database import get_db
from app.schemas.correction_request import CorrectionRequestCreate, CorrectionRequestReview, CorrectionRequestOut
from app.services import correction_service

router = APIRouter(prefix="/correction-requests", tags=["Correction Requests"])


@router.post("/", response_model=CorrectionRequestOut)
def create_correction_request(requested_by: int, data: CorrectionRequestCreate, db: Session = Depends(get_db)):
    return correction_service.create_correction_request(db, requested_by, data)


@router.get("/", response_model=list[CorrectionRequestOut])
def list_correction_requests(db: Session = Depends(get_db)):
    return correction_service.get_all_correction_requests(db)


@router.get("/user/{user_id}", response_model=list[CorrectionRequestOut])
def get_correction_requests_by_user(user_id: int, db: Session = Depends(get_db)):
    return correction_service.get_correction_requests_by_user(db, user_id)


@router.get("/group/{group_id}", response_model=list[CorrectionRequestOut])
def get_correction_requests_by_group(group_id: int, db: Session = Depends(get_db)):
    from app.models.user import User
    from app.models.attendance_record import AttendanceRecord
    return (
        db.query(CorrectionRequest)
        .join(AttendanceRecord, CorrectionRequest.attendance_record_id == AttendanceRecord.id)
        .join(User, AttendanceRecord.user_id == User.id)
        .filter(User.group_id == group_id)
        .all()
    )


@router.get("/{correction_id}", response_model=CorrectionRequestOut)
def get_correction_request(correction_id: int, db: Session = Depends(get_db)):
    return correction_service.get_correction_request(db, correction_id)


@router.put("/{correction_id}/review", response_model=CorrectionRequestOut)
def review_correction_request(
    correction_id: int, reviewer_id: int, data: CorrectionRequestReview, db: Session = Depends(get_db)
):
    return correction_service.review_correction_request(db, correction_id, reviewer_id, data)