from sqlalchemy import BigInteger, Column, DateTime, String, JSON
from sqlalchemy.sql import func

from app.core.database import Base


class Role(Base):
    """Data-driven roles (admin/manager/employee), not a hardcoded enum,
    so permissions can change without touching code. Matches the `roles`
    table in the architecture doc — permissions is a JSONB column, not
    a separate table.
    """

    __tablename__ = "roles"

    id = Column(BigInteger, primary_key=True, index=True)
    name = Column(String(30), unique=True, nullable=False)
    permissions = Column(JSON, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now())