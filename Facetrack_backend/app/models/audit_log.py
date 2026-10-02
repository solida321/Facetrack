# app/models/audit_log.py
from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class AuditLog(Base):
    """Tamper-evident record of create/update/delete actions on sensitive
    tables (users, face_profiles, attendance_records). actor_user_id is
    nullable to allow system-generated entries with no human actor.
    Matches the `audit_logs` table in the architecture doc.
    """

    __tablename__ = "audit_logs"

    id = Column(BigInteger, primary_key=True, index=True)
    actor_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=True)
    action = Column(String(20), nullable=False)  # create, update, delete
    entity_type = Column(String(50), nullable=False)  # 'users', 'face_profiles', 'attendance_records'...
    entity_id = Column(BigInteger, nullable=True)
    details = Column(JSONB, nullable=True)
    ip_address = Column(String(45), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    actor = relationship("User")