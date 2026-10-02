# app/api/routers/group.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.group import GroupCreate, GroupUpdate, GroupOut
from app.services import group_service

router = APIRouter(prefix="/groups", tags=["Groups"])


@router.post("/", response_model=GroupOut)
def create_group(data: GroupCreate, db: Session = Depends(get_db)):
    return group_service.create_group(db, data)


@router.get("/", response_model=list[GroupOut])
def list_groups(db: Session = Depends(get_db)):
    return group_service.get_all_groups(db)


@router.get("/{group_id}", response_model=GroupOut)
def get_group(group_id: int, db: Session = Depends(get_db)):
    return group_service.get_group(db, group_id)


@router.put("/{group_id}", response_model=GroupOut)
def update_group(group_id: int, data: GroupUpdate, db: Session = Depends(get_db)):
    return group_service.update_group(db, group_id, data)


@router.delete("/{group_id}")
def delete_group(group_id: int, db: Session = Depends(get_db)):
    group_service.delete_group(db, group_id)
    return {"detail": "Group deleted"}