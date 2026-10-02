# app/schemas/location.py
from datetime import datetime
from pydantic import BaseModel, Field


class LocationCreate(BaseModel):
    name: str
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    allowed_radius_meters: int = Field(default=100, gt=0)


class LocationUpdate(BaseModel):
    name: str | None = None
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    allowed_radius_meters: int | None = Field(default=None, gt=0)


class LocationOut(BaseModel):
    id: int
    name: str
    latitude: float
    longitude: float
    allowed_radius_meters: int
    created_at: datetime

    class Config:
        from_attributes = True