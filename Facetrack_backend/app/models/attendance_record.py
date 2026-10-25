# app/models/attendance_record.py
from sqlalchemy import BigInteger, Column, Date, DateTime, ForeignKey, Numeric, String, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class AttendanceRecord(Base):
    """The core event log — one row per user, per schedule, per date.
    Matches the `attendance_records` table in the architecture doc.

    The UNIQUE constraint on (schedule_id, user_id, attendance_date) is
    what prevents duplicate check-ins at the database level — Postgres
    itself rejects a second insert for the same combination.
    """

    __tablename__ = "attendance_records"
    __table_args__ = (
        UniqueConstraint(
            "schedule_id", "user_id", "attendance_date",
            name="uq_attendance_schedule_user_date"
        ),
    )

    id = Column(BigInteger, primary_key=True, index=True)
    schedule_id = Column(BigInteger, ForeignKey("schedules.id"), nullable=False)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    attendance_date = Column(Date, nullable=False)
    check_in_time = Column(DateTime(timezone=True), nullable=True)
    check_out_time = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(20), nullable=True)  # 'present', 'late', 'absent'
    check_in_latitude = Column(Numeric(9, 6), nullable=True)
    check_in_longitude = Column(Numeric(9, 6), nullable=True)
    check_in_device_id = Column(String(100), nullable=True)
    verification_method = Column(String(20), nullable=False, default="face")
    check_out_latitude = Column(Numeric(9, 6), nullable=True)
    check_out_longitude = Column(Numeric(9, 6), nullable=True)
    # NULL        = not checked out yet (or an old record / absent record)
    # 'on_time'   = checked out at or after the shift end
    # 'early_leave' = checked out before the shift end (allowed, but visible)
    # 'missing'   = nobody checked out in time (set by the job; the time is never invented)
    check_out_status = Column(String(20), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    schedule = relationship("Schedule")
    user = relationship("User")