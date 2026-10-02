from datetime import datetime
from pydantic import BaseModel, Field


class FaceProfileCreate(BaseModel):
    angle: str = Field(..., pattern="^(front|left|right)$")
    embedding: list[float] = Field(..., min_length=192, max_length=192)


class FaceProfileOut(BaseModel):
    id: int
    user_id: int
    angle: str
    quality_score: float | None
    created_at: datetime

    class Config:
        from_attributes = True