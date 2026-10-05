from sqlalchemy import BigInteger, Column, DateTime, Float, ForeignKey, Numeric, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.sql import func

from app.core.database import Base


class FaceProfile(Base):
    """One row per captured angle (front/left/right) for one user."""

    __tablename__ = "face_profiles"
    __table_args__ = (
        UniqueConstraint("user_id", "angle", name="uq_face_profiles_user_angle"),
    )

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    angle = Column(String(10), nullable=False)  # 'front', 'left', or 'right'
    embedding = Column(ARRAY(Float), nullable=False)
    quality_score = Column(Numeric(4, 3), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())