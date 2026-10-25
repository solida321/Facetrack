# app/services/audit_service.py
from fastapi import Request
from sqlalchemy.orm import Session
from fastapi import Request
from app.models.user import User

from app.models.audit_log import AuditLog
def record_audit(
    db: Session,
    request: Request | None,
    actor: User | None,
    action: str,
    entity_type: str,
    entity_id: int | None = None,
    details: dict | None = None,
) -> None:
    try:
        write_audit_log(
            db,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            actor_user_id=actor.id if actor else None,
            details=details,
            ip_address=request.client.host if request is not None and request.client else None,
        )
    except Exception as e:  # noqa: BLE001
        db.rollback()
        print("audit log failed:", e)

def write_audit_log(
    db: Session,
    action: str,
    entity_type: str,
    entity_id: int | None = None,
    actor_user_id: int | None = None,
    details: dict | None = None,
    ip_address: str | None = None,
) -> AuditLog:
    """Call this from inside other services whenever a sensitive
    create/update/delete happens — e.g. inside group_service.create_group(),
    or attendance_service after a correction is applied.
    """
    log = AuditLog(
        actor_user_id=actor_user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        details=details,
        ip_address=ip_address,
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    return log


def get_all_audit_logs(db: Session) -> list[AuditLog]:
    return db.query(AuditLog).order_by(AuditLog.created_at.desc()).all()


def get_audit_logs_by_entity(db: Session, entity_type: str, entity_id: int) -> list[AuditLog]:
    return db.query(AuditLog).filter(
        AuditLog.entity_type == entity_type,
        AuditLog.entity_id == entity_id
    ).order_by(AuditLog.created_at.desc()).all()

def record_audit(
    db: Session,
    request: Request | None,
    actor: User | None,
    action: str,
    entity_type: str,
    entity_id: int | None = None,
    details: dict | None = None,
) -> None:
    try:
        write_audit_log(
            db,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            actor_user_id=actor.id if actor else None,
            details=details,
            ip_address=request.client.host if request is not None and request.client else None,
        )
    except Exception as e:  # noqa: BLE001
        db.rollback()
        print("audit log failed:", e)