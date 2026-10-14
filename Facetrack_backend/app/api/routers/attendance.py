# app/api/routers/attendance.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.attendance_record import CheckInRequest, CheckOutRequest, AttendanceRecordOut
from app.services import attendance_service
from app.services import absence_service

router = APIRouter(prefix="/attendance", tags=["Attendance"])


@router.post("/check-in", response_model=AttendanceRecordOut)
def check_in(data: CheckInRequest, db: Session = Depends(get_db)):
    return attendance_service.check_in(db, data)


@router.post("/check-out", response_model=AttendanceRecordOut)
def check_out(data: CheckOutRequest, db: Session = Depends(get_db)):
    return attendance_service.check_out(db, data)


@router.get("/", response_model=list[AttendanceRecordOut])
def list_attendance(db: Session = Depends(get_db)):
    return attendance_service.get_all_attendance(db)


@router.get("/{record_id}", response_model=AttendanceRecordOut)
def get_attendance(record_id: int, db: Session = Depends(get_db)):
    return attendance_service.get_attendance_record(db, record_id)


@router.get("/user/{user_id}", response_model=list[AttendanceRecordOut])
def get_user_attendance(user_id: int, db: Session = Depends(get_db)):
    return attendance_service.get_attendance_by_user(db, user_id)


@router.post("/mark-absences")
def run_absence_job(db: Session = Depends(get_db)):
    return {"created": absence_service.mark_absences(db)}