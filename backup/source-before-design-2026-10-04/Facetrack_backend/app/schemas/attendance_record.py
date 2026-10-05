# app/schemas/attendance_record.py
from datetime import date, datetime
from pydantic import BaseModel, Field


class CheckInRequest(BaseModel):
    schedule_id: int
    user_id: int
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    device_id: str | None = None
    face_embedding: list[float] = Field(..., min_length=192, max_length=192)


class CheckOutRequest(BaseModel):
    attendance_record_id: int
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


class AttendanceRecordOut(BaseModel):
    id: int
    schedule_id: int
    user_id: int
    attendance_date: date
    check_in_time: datetime | None
    check_out_time: datetime | None
    status: str | None
    check_in_latitude: float | None
    check_in_longitude: float | None
    check_in_device_id: str | None
    verification_method: str
    created_at: datetime

    class Config:
        from_attributes = True