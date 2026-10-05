# app/models/correction_request.py
from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class CorrectionRequest(Base):
    """Disputes an existing attendance_records row — 'this record is wrong,
    please fix it.' Separate from LeaveRequest, which is for future absence.
    Matches the `attendance_correction_requests` table in the architecture doc.
    """

    __tablename__ = "attendance_correction_requests"

    id = Column(BigInteger, primary_key=True, index=True)
    attendance_record_id = Column(BigInteger, ForeignKey("attendance_records.id"), nullable=False)
    requested_by = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    requested_status = Column(String(20), nullable=True)  # present, late, absent
    requested_check_in_time = Column(DateTime(timezone=True), nullable=True)
    requested_check_out_time = Column(DateTime(timezone=True), nullable=True)
    reason = Column(Text, nullable=False)
    status = Column(String(20), nullable=False, default="pending")  # pending, approved, rejected
    reviewed_by = Column(BigInteger, ForeignKey("users.id"), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    attendance_record = relationship("AttendanceRecord")
    requester = relationship("User", foreign_keys=[requested_by])
    reviewer = relationship("User", foreign_keys=[reviewed_by])