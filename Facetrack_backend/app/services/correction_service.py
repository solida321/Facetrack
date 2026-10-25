from datetime import datetime, timezone

from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.correction_request import CorrectionRequest
from app.models.attendance_record import AttendanceRecord
from app.models.notification import Notification
from app.schemas.correction_request import CorrectionRequestCreate, CorrectionRequestReview


def create_correction_request(db: Session, requested_by: int, data: CorrectionRequestCreate) -> CorrectionRequest:
    record = db.query(AttendanceRecord).filter(AttendanceRecord.id == data.attendance_record_id).first()
    
    if record.user_id != requested_by:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only request corrections for your own attendance")
    if record.status == "present":
        raise HTTPException(status_code=400, detail="Present records cannot be corrected")

    already_pending = db.query(CorrectionRequest).filter(
        CorrectionRequest.attendance_record_id == data.attendance_record_id,
        CorrectionRequest.status == "pending",
    ).first()
    if already_pending:
        raise HTTPException(status_code=400, detail="A correction for this record is already pending")
    correction = CorrectionRequest(
        attendance_record_id=data.attendance_record_id,
        requested_by=requested_by,
        requested_status=data.requested_status,
        requested_check_in_time=data.requested_check_in_time,
        requested_check_out_time=data.requested_check_out_time,
        reason=data.reason,
        status="pending",
    )
    db.add(correction)
    db.commit()
    db.refresh(correction)
    return correction


def get_correction_request(db: Session, correction_id: int) -> CorrectionRequest:
    correction = db.query(CorrectionRequest).filter(CorrectionRequest.id == correction_id).first()
    if not correction:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Correction request not found")
    return correction


def get_all_correction_requests(db: Session) -> list[CorrectionRequest]:
    return db.query(CorrectionRequest).all()


def get_correction_requests_by_user(db: Session, user_id: int) -> list[CorrectionRequest]:
    return db.query(CorrectionRequest).filter(CorrectionRequest.requested_by == user_id).all()


def review_correction_request(
    db: Session, correction_id: int, reviewer_id: int, data: CorrectionRequestReview
) -> CorrectionRequest:
    correction = get_correction_request(db, correction_id)
    if correction.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This request has already been reviewed")

    correction.status = data.status
    correction.reviewed_by = reviewer_id
    correction.reviewed_at = datetime.now(timezone.utc)

    db.add(Notification(
        user_id=correction.requested_by,
        title=f"Correction request {data.status}",
        message=f"Your attendance correction request was {data.status}.",
        type=f"correction_{data.status}",
    ))

    # If approved, actually apply the fix to the attendance record
    if data.status == "approved":
        record = db.query(AttendanceRecord).filter(
            AttendanceRecord.id == correction.attendance_record_id
        ).first()
        if correction.requested_status:
            record.status = correction.requested_status
        if correction.requested_check_in_time:
            record.check_in_time = correction.requested_check_in_time
        if correction.requested_check_out_time:
            record.check_out_time = correction.requested_check_out_time

    db.commit()
    db.refresh(correction)
    return correction