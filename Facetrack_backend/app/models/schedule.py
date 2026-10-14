# app/models/schedule.py
from sqlalchemy import BigInteger, CheckConstraint, Column, Date, DateTime, ForeignKey, Integer, SmallInteger, String, Time
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base
from sqlalchemy import Boolean, text  

class Schedule(Base):
    """Defines when a group (department/team) works, and where.
    Matches the `schedules` table in the architecture doc.

    Either day_of_week (recurring weekly shift) or specific_date
    (one-off shift) must be set — enforced by the CheckConstraint below.
    """

    __tablename__ = "schedules"
    __table_args__ = (
        CheckConstraint(
            "day_of_week IS NOT NULL OR specific_date IS NOT NULL",
            name="ck_schedules_day_or_date"
        ),
    )

    id = Column(BigInteger, primary_key=True, index=True)
    group_id = Column(BigInteger, ForeignKey("groups.id"), nullable=False)
    session_name = Column(String(150), nullable=False)  # e.g. "Morning Shift"
    day_of_week = Column(SmallInteger, nullable=True)    # 0=Mon ... 6=Sun
    specific_date = Column(Date, nullable=True)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    grace_period_minutes = Column(Integer, nullable=False, default=10)
    location_id = Column(BigInteger, ForeignKey("locations.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_active = Column(Boolean, nullable=False, default=True, server_default=text("true"))

    group = relationship("Group")
    location = relationship("Location")