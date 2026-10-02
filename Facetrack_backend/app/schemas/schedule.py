# app/schemas/schedule.py
from datetime import date, datetime, time
from pydantic import BaseModel, Field, model_validator


class ScheduleCreate(BaseModel):
    group_id: int
    session_name: str
    day_of_week: int | None = Field(default=None, ge=0, le=6)
    specific_date: date | None = None
    start_time: time
    end_time: time
    grace_period_minutes: int = Field(default=10, ge=0)
    location_id: int | None = None

    @model_validator(mode="after")
    def check_day_or_date(self):
        if self.day_of_week is None and self.specific_date is None:
            raise ValueError("Either day_of_week or specific_date must be provided")
        return self


class ScheduleUpdate(BaseModel):
    session_name: str | None = None
    day_of_week: int | None = Field(default=None, ge=0, le=6)
    specific_date: date | None = None
    start_time: time | None = None
    end_time: time | None = None
    grace_period_minutes: int | None = Field(default=None, ge=0)
    location_id: int | None = None


class ScheduleOut(BaseModel):
    id: int
    group_id: int
    session_name: str
    day_of_week: int | None
    specific_date: date | None
    start_time: time
    end_time: time
    grace_period_minutes: int
    location_id: int | None
    created_at: datetime

    class Config:
        from_attributes = True