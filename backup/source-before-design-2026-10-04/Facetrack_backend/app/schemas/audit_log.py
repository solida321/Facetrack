# app/schemas/audit_log.py
from datetime import datetime
from pydantic import BaseModel


class AuditLogOut(BaseModel):
    id: int
    actor_user_id: int | None
    action: str
    entity_type: str
    entity_id: int | None
    details: dict | None
    ip_address: str | None
    created_at: datetime

    class Config:
        from_attributes = True