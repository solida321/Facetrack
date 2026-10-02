from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    """Matches the `users` table in the architecture doc.

    group_id is intentionally left as a plain nullable column for now,
    with no ForeignKey constraint yet — the `groups` table doesn't exist
    in the database until we build that model. We'll add the constraint
    back in a later migration once groups.py exists, same one-feature-
    at-a-time approach we used on the Flutter side.
    """

    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, index=True)
    full_name = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, nullable=False, index=True)
    phone = Column(String(30), nullable=True)
    password_hash = Column(String(255), nullable=False)
    external_id = Column(String(50), nullable=True)
    gender = Column(String(10), nullable=True)
    
    group_id = Column(BigInteger, ForeignKey("groups.id"), nullable=True)  # FK added once groups.py exists
    role_id = Column(BigInteger, ForeignKey("roles.id"), nullable=False)
    status = Column(String(20), nullable=False, default="pending_approval")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), nullable=True)

    role = relationship("Role")
    group = relationship("Group", foreign_keys=[group_id])

