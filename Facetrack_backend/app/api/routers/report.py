import csv
import io
from datetime import date, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from openpyxl import Workbook
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.attendance_record import AttendanceRecord
from app.models.group import Group
from app.models.schedule import Schedule
from app.models.user import User
from app.services.absence_service import mark_absences

router = APIRouter(prefix="/reports", tags=["Reports"])

CAMBODIA_TZ = timezone(timedelta(hours=7))
HEADERS = ["Date", "Employee", "Email", "Team", "Shift", "Status", "Check-in", "Check-out"]


def _time(value):
    return value.astimezone(CAMBODIA_TZ).strftime("%H:%M") if value else ""


@router.get("/attendance")
def attendance_report(
    date_from: date,
    date_to: date,
    format: str = Query("csv", pattern="^(csv|xlsx)$"),
    group_id: str | None = None,
    db: Session = Depends(get_db),
):
    mark_absences(db)  # make sure missed shifts are recorded before exporting

    # A blank or missing group_id means "all teams".
    team_id = int(group_id) if group_id and group_id.isdigit() else None

    query = (
        db.query(AttendanceRecord, User, Schedule, Group)
        .join(User, AttendanceRecord.user_id == User.id)
        .join(Schedule, AttendanceRecord.schedule_id == Schedule.id)
        .join(Group, Schedule.group_id == Group.id)
        .filter(AttendanceRecord.attendance_date >= date_from, AttendanceRecord.attendance_date <= date_to)
    )
    if team_id is not None:
        query = query.filter(Group.id == team_id)

    records = query.order_by(AttendanceRecord.attendance_date, User.full_name).all()

    rows = [
        [
            str(r.attendance_date), u.full_name, u.email, g.name, s.session_name,
            r.status or "", _time(r.check_in_time), _time(r.check_out_time),
        ]
        for r, u, s, g in records
    ]

    if format == "xlsx":
        wb = Workbook()
        ws = wb.active
        ws.title = "Attendance"
        ws.append(HEADERS)
        for row in rows:
            ws.append(row)
        buf = io.BytesIO()
        wb.save(buf)
        return Response(
            content=buf.getvalue(),
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )

    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(HEADERS)
    writer.writerows(rows)
    # The BOM makes Excel open the CSV as UTF-8 so names display correctly.
    return Response(content="\ufeff" + out.getvalue(), media_type="text/csv; charset=utf-8")