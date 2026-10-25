# app/services/attendance_export_service.py
"""Builds the attendance report as CSV text (opens in Excel and Google Sheets)."""
import csv
import io
from datetime import date, datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models.attendance_record import AttendanceRecord
from app.models.group import Group
from app.models.schedule import Schedule
from app.models.user import User
from app.services.attendance_service import get_all_attendance

CAMBODIA_TZ = timezone(timedelta(hours=7))

CHECK_OUT_NOTE = {
    "early_leave": "Early leave",
    "missing": "Missing check-out",
    "on_time": "",
}


def _hhmm(dt: datetime | None) -> str:
    if dt is None:
        return ""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=CAMBODIA_TZ)
    return dt.astimezone(CAMBODIA_TZ).strftime("%H:%M")


def build_attendance_csv(
    db: Session,
    actor: User,
    date_from: date | None = None,
    date_to: date | None = None,
    group_id: int | None = None,
) -> str:
    """Admin gets everyone, a manager only their own team (same rule as the list)."""
    today = datetime.now(CAMBODIA_TZ).date()
    date_to = date_to or today
    date_from = date_from or (date_to - timedelta(days=30))

    records = [
        r for r in get_all_attendance(db, actor)
        if date_from <= r.attendance_date <= date_to
    ]

    users = {u.id: u for u in db.query(User).all()}
    groups = {g.id: g.name for g in db.query(Group).all()}
    schedules = {s.id: s for s in db.query(Schedule).all()}

    if group_id is not None:
        records = [r for r in records if users.get(r.user_id) and users[r.user_id].group_id == group_id]

    records.sort(key=lambda r: (r.attendance_date, r.user_id))

    out = io.StringIO()
    out.write("﻿")  # BOM: makes Excel read Khmer / Chinese names correctly
    w = csv.writer(out)
    w.writerow([
        "Date", "Employee", "Email", "Team", "Shift",
        "Check-in", "Check-out", "Status", "Check-out note",
        "Check-in GPS", "Check-out GPS",
    ])
    for r in records:
        u = users.get(r.user_id)
        s = schedules.get(r.schedule_id)
        w.writerow([
            r.attendance_date.isoformat(),
            u.full_name if u else r.user_id,
            u.email if u else "",
            groups.get(u.group_id, "") if u else "",
            f"{s.session_name} {s.start_time.strftime('%H:%M')}-{s.end_time.strftime('%H:%M')}" if s else "",
            _hhmm(r.check_in_time),
            _hhmm(r.check_out_time),
            r.status or "",
            CHECK_OUT_NOTE.get(r.check_out_status or "", ""),
            f"{r.check_in_latitude},{r.check_in_longitude}" if r.check_in_latitude is not None else "",
            f"{r.check_out_latitude},{r.check_out_longitude}" if r.check_out_latitude is not None else "",
        ])
    return out.getvalue()