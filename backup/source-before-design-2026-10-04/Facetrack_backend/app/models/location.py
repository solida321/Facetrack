# app/models/location.py
from sqlalchemy import BigInteger, Column, DateTime, Integer, Numeric, String
from sqlalchemy.sql import func

from app.core.database import Base


class Location(Base):
    """One row per allowed check-in site (office, building, branch).
    Matches the `locations` table in the architecture doc.
    """

    __tablename__ = "locations"

    id = Column(BigInteger, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    latitude = Column(Numeric(9, 6), nullable=False)
    longitude = Column(Numeric(9, 6), nullable=False)
    allowed_radius_meters = Column(Integer, nullable=False, default=100)
    created_at = Column(DateTime(timezone=True), server_default=func.now())