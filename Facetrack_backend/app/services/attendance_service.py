import os
from datetime import datetime, timezone, timedelta

from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status

from app.core.face_matching import MATCH_THRESHOLD
from app.models.attendance_record import AttendanceRecord
from app.models.schedule import Schedule
from app.models.location import Location
from app.models.notification import Notification
from app.models.user import User
from app.core.permissions import is_admin
from app.schemas.attendance_record import CheckInRequest, CheckOutRequest
from app.core.geo import is_within_allowed_radius
from app.services.face_profile_service import verify_face

CAMBODIA_TZ = timezone(timedelta(hours=7))

# How long after the shift ends a check-out is still accepted.
CHECKOUT_WINDOW_HOURS = int(os.getenv("CHECKOUT_WINDOW_HOURS", "3"))
# Same location rule as check-in. Set REQUIRE_CHECKOUT_LOCATION=false to switch it off.
REQUIRE_CHECKOUT_LOCATION = os.getenv("REQUIRE_CHECKOUT_LOCATION", "true").lower() != "false"


def _local(dt: datetime) -> datetime:
    """Makes sure a time has a timezone (SQLite gives back naive times)."""
    return dt if dt.tzinfo else dt.replace(tzinfo=CAMBODIA_TZ)


def shift_end_of(record: AttendanceRecord, schedule: Schedule) -> datetime:
    return datetime.combine(record.attendance_date, schedule.end_time, tzinfo=CAMBODIA_TZ)


def refresh_checkout_flags(record: AttendanceRecord, schedule: Schedule) -> None:
    """Sets check_out_status from the real times: 'on_time' or 'early_leave'.
    Used after a check-out and after an approved correction.
    With no check-out time it does nothing (a 'missing' flag stays)."""
    if record.check_out_time is None:
        return
    left_before_end = _local(record.check_out_time) < shift_end_of(record, schedule)
    record.check_out_status = "early_leave" if left_before_end else "on_time"


def check_in(db: Session, data: CheckInRequest, user: User) -> AttendanceRecord:
    """`user` is the logged-in person from the token — never trust a user id sent by the phone."""
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
    face_matched, face_score = verify_face(db, user.id, data.face_embedding)
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
        user_id=user.id,
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
        user_id=user.id,
        title=notif_title,
        message=notif_message,
        type="check_in_success" if attendance_status == "present" else "late_warning",
    ))
    db.commit()

    return record


def check_out(db: Session, data: CheckOutRequest, user: User) -> AttendanceRecord:
    record = db.query(AttendanceRecord).filter(
        AttendanceRecord.id == data.attendance_record_id
    ).first()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found")
    # You can only check out of your own attendance record.
    if record.user_id != user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="This is not your attendance record")
    if record.check_in_time is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You have not checked in for this shift")
    if record.check_out_time is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already checked out")

    schedule = db.query(Schedule).filter(Schedule.id == record.schedule_id).first()
    now_local = datetime.now(CAMBODIA_TZ)

    if schedule is not None:
        # Closing window: after shift end + a few hours the system stops accepting it,
        # so a check-out cannot be stamped the next morning.
        closes_at = shift_end_of(record, schedule) + timedelta(hours=CHECKOUT_WINDOW_HOURS)
        if now_local > closes_at:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="The check-out time for this shift has closed. Send a correction request with your real check-out time.",
            )

        # Same location rule as check-in, so nobody can check out from home.
        if REQUIRE_CHECKOUT_LOCATION and schedule.location_id:
            location = db.query(Location).filter(Location.id == schedule.location_id).first()
            if location and not is_within_allowed_radius(data.latitude, data.longitude, location):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="You are outside the allowed check-out area",
                )

    record.check_out_time = now_local
    record.check_out_latitude = data.latitude
    record.check_out_longitude = data.longitude
    if schedule is not None:
        refresh_checkout_flags(record, schedule)

    message = f"You checked out at {now_local.strftime('%H:%M')}."
    if record.check_out_status == "early_leave":
        message += " This is recorded as left early."
    db.add(Notification(
        user_id=user.id,
        title="Check-out saved",
        message=message,
        type="check_out_success",
    ))
    db.commit()
    db.refresh(record)
    return record


def get_attendance_record(db: Session, record_id: int) -> AttendanceRecord:
    record = db.query(AttendanceRecord).filter(AttendanceRecord.id == record_id).first()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found")
    return record


def get_attendance_by_user(db: Session, user_id: int) -> list[AttendanceRecord]:
    return (
        db.query(AttendanceRecord)
        .filter(AttendanceRecord.user_id == user_id)
        .order_by(AttendanceRecord.attendance_date.desc(), AttendanceRecord.id.desc())
        .all()
    )


def get_all_attendance(db: Session, actor: User | None = None) -> list[AttendanceRecord]:
    """Admin sees every record. A manager only sees records of people in
    their own group (and nothing if they have no group)."""
    query = db.query(AttendanceRecord)
    if actor is not None and not is_admin(actor):
        if actor.group_id is None:
            return []
        query = query.join(User, AttendanceRecord.user_id == User.id).filter(User.group_id == actor.group_id)
    return query.order_by(AttendanceRecord.attendance_date.desc(), AttendanceRecord.id.desc()).all()