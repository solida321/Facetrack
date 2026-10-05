# app/schemas/leave_request.py
from datetime import date, datetime
from pydantic import BaseModel, Field, model_validator


class LeaveRequestCreate(BaseModel):
    date_from: date
    date_to: date
    reason: str | None = None

    @model_validator(mode="after")
    def check_date_range(self):
        if self.date_to < self.date_from:
            raise ValueError("date_to cannot be before date_from")
        return self


class LeaveRequestReview(BaseModel):
    status: str = Field(..., pattern="^(approved|rejected)$")


class LeaveRequestOut(BaseModel):
    id: int
    user_id: int
    date_from: date
    date_to: date
    reason: str | None
    status: str
    reviewed_by: int | None
    reviewed_at: datetime | None
    created_at: datetime

    class Config:
        from_attributes = True