# app/api/routers/attendance.py
from datetime import date

from fastapi import APIRouter, Depends
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin, require_staff
from app.core.permissions import ensure_can_access_user
from app.models.user import User
from app.schemas.attendance_record import CheckInRequest, CheckOutRequest, AttendanceRecordOut
from app.services import attendance_service
from app.services import absence_service
from app.services import attendance_export_service

router = APIRouter(prefix="/attendance", tags=["Attendance"])


@router.post("/check-in", response_model=AttendanceRecordOut)
def check_in(
    data: CheckInRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Who is checking in comes from the token, not from the request body.
    return attendance_service.check_in(db, data, current_user)


@router.post("/check-out", response_model=AttendanceRecordOut)
def check_out(
    data: CheckOutRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return attendance_service.check_out(db, data, current_user)


@router.get("/", response_model=list[AttendanceRecordOut])
def list_attendance(db: Session = Depends(get_db), current_user: User = Depends(require_staff)):
    return attendance_service.get_all_attendance(db, current_user)


@router.get("/export")
def export_attendance(
    date_from: date | None = None,
    date_to: date | None = None,
    group_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    """CSV report. Admin: everyone. Manager: own team only."""
    csv_text = attendance_export_service.build_attendance_csv(db, current_user, date_from, date_to, group_id)
    return Response(
        content=csv_text,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": 'attachment; filename="attendance.csv"'},
    )


@router.get("/user/{user_id}", response_model=list[AttendanceRecordOut])
def get_user_attendance(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_can_access_user(db, current_user, user_id)
    return attendance_service.get_attendance_by_user(db, user_id)


@router.get("/{record_id}", response_model=AttendanceRecordOut)
def get_attendance(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    record = attendance_service.get_attendance_record(db, record_id)
    ensure_can_access_user(db, current_user, record.user_id)
    return record


@router.post("/mark-absences")
def run_absence_job(db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    return {
        "created": absence_service.mark_absences(db),
        "missing_checkouts": absence_service.mark_missing_checkouts(db),
    }