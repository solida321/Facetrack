from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status

from app.core.face_matching import MATCH_THRESHOLD
from app.models.attendance_record import AttendanceRecord
from app.models.schedule import Schedule
from app.models.location import Location
from app.models.notification import Notification
from app.schemas.attendance_record import CheckInRequest, CheckOutRequest
from app.core.geo import is_within_allowed_radius
from app.services.face_profile_service import verify_face

CAMBODIA_TZ = timezone(timedelta(hours=7))


def check_in(db: Session, data: CheckInRequest) -> AttendanceRecord:
    schedule = db.query(Schedule).filter(Schedule.id == data.schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Schedule not found")

    # GPS validation — only if the schedule has a location attached
    if schedule.location_id:
        location = db.query(Location).filter(Location.id == schedule.location_id).first()
        if location and not is_within_allowed_radius(data.latitude, data.longitude, location):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are outside the allowed check-in area"
            )

    # Face verification — backend-side, per the security decision
    face_matched, face_score = verify_face(db, data.user_id, data.face_embedding)
    if not face_matched:
        raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Face verification failed. Please try again."
    )

    now_local = datetime.now(CAMBODIA_TZ)
    today = now_local.date()

    EARLY_CHECKIN_WINDOW_MINUTES = 30  # how early someone may check in before the shift starts

    scheduled_start = datetime.combine(today, schedule.start_time, tzinfo=CAMBODIA_TZ)
    earliest_allowed = scheduled_start - timedelta(minutes=EARLY_CHECKIN_WINDOW_MINUTES)

    # check if the shift has already ended
    shift_end = datetime.combine(today, schedule.end_time, tzinfo=CAMBODIA_TZ)
    if now_local > shift_end:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This shift has already ended."
        )
    #check if the shift has not started yet

    if now_local < earliest_allowed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Too early to check in. This shift starts at {schedule.start_time.strftime('%H:%M')}."
        )

    grace_deadline = scheduled_start + timedelta(minutes=schedule.grace_period_minutes)
    attendance_status = "present" if now_local <= grace_deadline else "late"

    record = AttendanceRecord(
        schedule_id=data.schedule_id,
        user_id=data.user_id,
        attendance_date=today,
        check_in_time=now_local,
        status=attendance_status,
        check_in_latitude=data.latitude,
        check_in_longitude=data.longitude,
        check_in_device_id=data.device_id,
        verification_method="face",
    )

    db.add(record)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already checked in for this schedule today"
        )
    db.refresh(record)

    # Notify the user of the result
    notif_title = "Check-in successful" if attendance_status == "present" else "Late check-in recorded"
    notif_message = f"You checked in at {now_local.strftime('%H:%M')}."
    db.add(Notification(
        user_id=data.user_id,
        title=notif_title,
        message=notif_message,
        type="check_in_success" if attendance_status == "present" else "late_warning",
    ))
    db.commit()

    return record


def check_out(db: Session, data: CheckOutRequest) -> AttendanceRecord:
    record = db.query(AttendanceRecord).filter(
        AttendanceRecord.id == data.attendance_record_id
    ).first()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found")
    if record.check_out_time is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already checked out")

    record.check_out_time = datetime.now(CAMBODIA_TZ)
    db.commit()
    db.refresh(record)
    return record


def get_attendance_record(db: Session, record_id: int) -> AttendanceRecord:
    record = db.query(AttendanceRecord).filter(AttendanceRecord.id == record_id).first()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found")
    return record


def get_attendance_by_user(db: Session, user_id: int) -> list[AttendanceRecord]:
    return db.query(AttendanceRecord).filter(AttendanceRecord.user_id == user_id).all()


def get_all_attendance(db: Session) -> list[AttendanceRecord]:
    return db.query(AttendanceRecord).all()