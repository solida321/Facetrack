# app/schemas/group.py
from datetime import datetime
from pydantic import BaseModel, Field


class GroupCreate(BaseModel):
    name: str
    type: str = Field(..., pattern="^(class|department|team)$")
    owner_user_id: int | None = None


class GroupUpdate(BaseModel):
    name: str | None = None
    type: str | None = Field(default=None, pattern="^(class|department|team)$")
    owner_user_id: int | None = None


class GroupOut(BaseModel):
    id: int
    name: str
    type: str
    owner_user_id: int | None
    created_at: datetime

    class Config:
        from_attributes = True