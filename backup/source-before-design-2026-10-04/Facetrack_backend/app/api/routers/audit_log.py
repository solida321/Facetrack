# app/api/routers/audit_log.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.audit_log import AuditLogOut
from app.services import audit_service

router = APIRouter(prefix="/audit-logs", tags=["Audit Logs"])


@router.get("/", response_model=list[AuditLogOut])
def list_audit_logs(db: Session = Depends(get_db)):
    return audit_service.get_all_audit_logs(db)


@router.get("/{entity_type}/{entity_id}", response_model=list[AuditLogOut])
def get_logs_for_entity(entity_type: str, entity_id: int, db: Session = Depends(get_db)):
    return audit_service.get_audit_logs_by_entity(db, entity_type, entity_id)