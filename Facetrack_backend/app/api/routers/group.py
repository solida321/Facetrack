# app/api/routers/group.py
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.models.user import User
from app.schemas.group import GroupCreate, GroupUpdate, GroupOut
from app.services import group_service
from app.services.audit_service import record_audit

router = APIRouter(prefix="/groups", tags=["Groups"])


@router.post("/", response_model=GroupOut)
def create_group(
    data: GroupCreate,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    group = group_service.create_group(db, data)
    record_audit(db, request, admin, "create", "groups", group.id, {"name": group.name, "type": group.type})
    return group


@router.get("/", response_model=list[GroupOut])
def list_groups(db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    return group_service.get_all_groups(db)


@router.get("/{group_id}", response_model=GroupOut)
def get_group(group_id: int, db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    return group_service.get_group(db, group_id)


@router.put("/{group_id}", response_model=GroupOut)
def update_group(
    group_id: int,
    data: GroupUpdate,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    group = group_service.update_group(db, group_id, data)
    record_audit(db, request, admin, "update", "groups", group_id, {"changed": data.model_dump(exclude_unset=True)})
    return group


@router.delete("/{group_id}")
def delete_group(
    group_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    group_service.delete_group(db, group_id)
    record_audit(db, request, admin, "delete", "groups", group_id)
    return {"detail": "Group deleted"}
