from datetime import datetime, timedelta, timezone

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.attendance_record import AttendanceRecord
from app.models.notification import Notification
from app.models.leave_request import LeaveRequest
from app.models.role import Role
from app.models.schedule import Schedule
from app.models.user import User
from app.services.attendance_service import CHECKOUT_WINDOW_HOURS, shift_end_of

CAMBODIA_TZ = timezone(timedelta(hours=7))


def mark_absences(db: Session, days_back: int = 30) -> int:
    """Creates an 'absent' record for every active member who had a shift
    that already ended and has no attendance record for it. Returns how
    many records were created."""
    now = datetime.now(CAMBODIA_TZ)
    created = 0

    schedules = (
        db.query(Schedule)
        .filter(Schedule.is_active.is_(True), Schedule.day_of_week.isnot(None))
        .all()
    )

    for offset in range(days_back):
        day = (now - timedelta(days=offset)).date()

        for s in schedules:
            if s.day_of_week != day.weekday():
                continue

            shift_end = datetime.combine(day, s.end_time, tzinfo=CAMBODIA_TZ)
            if now <= shift_end:
                continue  # shift hasn't finished yet
            if s.created_at and s.created_at.astimezone(CAMBODIA_TZ) >= shift_end:
                continue  # schedule didn't exist yet when this shift ended

            members = (
                db.query(User)
                .join(Role, User.role_id == Role.id)
                .filter(User.group_id == s.group_id, User.status == "active", Role.name != "admin")
                .all()
            )

            for u in members:
                if u.created_at and u.created_at.astimezone(CAMBODIA_TZ) >= shift_end:
                    continue  # account didn't exist yet

                has_record = db.query(AttendanceRecord.id).filter(
                    AttendanceRecord.schedule_id == s.id,
                    AttendanceRecord.user_id == u.id,
                    AttendanceRecord.attendance_date == day,
                ).first()
                if has_record:
                    continue

                on_leave = db.query(LeaveRequest.id).filter(
                    LeaveRequest.user_id == u.id,
                    LeaveRequest.status == "approved",
                    LeaveRequest.date_from <= day,
                    LeaveRequest.date_to >= day,
                ).first()
                if on_leave:
                    continue

                db.add(AttendanceRecord(
                    schedule_id=s.id,
                    user_id=u.id,
                    attendance_date=day,
                    status="absent",
                    verification_method="none",
                ))
                db.add(Notification(
                    user_id=u.id,
                    title="Marked absent",
                    message=f"You were marked absent on {day} ({s.start_time.strftime('%H:%M')}-{s.end_time.strftime('%H:%M')}). "
                            "If this is wrong, send a correction request.",
                    type="absent",
                ))
                created += 1

    try:
        db.commit()
    except IntegrityError:
        db.rollback()  # a live check-in raced us; the next run retries
        return 0
    return created


def mark_missing_checkouts(db: Session, days_back: int = 30) -> int:
    """Marks records as "missing" where the person checked in but never checked out, and the
    check-out window is over. It does NOT invent a check-out time: the employee
    must send a correction request with the real time. Each record is flagged
    once, and the employee is told once."""
    now = datetime.now(CAMBODIA_TZ)
    since = (now - timedelta(days=days_back)).date()

    records = (
        db.query(AttendanceRecord)
        .filter(
            AttendanceRecord.check_in_time.isnot(None),
            AttendanceRecord.check_out_time.is_(None),
            AttendanceRecord.check_out_status.is_(None),
            AttendanceRecord.attendance_date >= since,
        )
        .all()
    )

    flagged = 0
    for r in records:
        schedule = db.query(Schedule).filter(Schedule.id == r.schedule_id).first()
        if schedule is None:
            continue
        if now <= shift_end_of(r, schedule) + timedelta(hours=CHECKOUT_WINDOW_HOURS):
            continue  # still inside the check-out window
        r.check_out_status = "missing"
        db.add(Notification(
            user_id=r.user_id,
            title="Missing check-out",
            message=f"You did not check out on {r.attendance_date}. "
                    "Send a correction request with your real check-out time.",
            type="missing_checkout",
        ))
        flagged += 1

    db.commit()
    return flagged