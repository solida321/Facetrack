# app/schemas/correction_request.py
from datetime import datetime
from pydantic import BaseModel, Field


class CorrectionRequestCreate(BaseModel):
    attendance_record_id: int
    requested_status: str | None = Field(default=None, pattern="^(present|late|absent)$")
    requested_check_in_time: datetime | None = None
    requested_check_out_time: datetime | None = None
    reason: str


class CorrectionRequestReview(BaseModel):
    status: str = Field(..., pattern="^(approved|rejected)$")


class CorrectionRequestOut(BaseModel):
    id: int
    attendance_record_id: int
    requested_by: int
    requested_status: str | None
    requested_check_in_time: datetime | None
    requested_check_out_time: datetime | None
    reason: str
    status: str
    reviewed_by: int | None
    reviewed_at: datetime | None
    created_at: datetime

    class Config:
        from_attributes = True