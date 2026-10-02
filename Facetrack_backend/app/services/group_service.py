# app/services/group_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.group import Group
from app.schemas.group import GroupCreate, GroupUpdate


def create_group(db: Session, data: GroupCreate) -> Group:
    group = Group(
        name=data.name,
        type=data.type,
        owner_user_id=data.owner_user_id,
    )
    db.add(group)
    db.commit()
    db.refresh(group)
    return group


def get_group(db: Session, group_id: int) -> Group:
    group = db.query(Group).filter(Group.id == group_id).first()
    if not group:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    return group


def get_all_groups(db: Session) -> list[Group]:
    return db.query(Group).all()


def update_group(db: Session, group_id: int, data: GroupUpdate) -> Group:
    group = get_group(db, group_id)
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(group, field, value)
    db.commit()
    db.refresh(group)
    return group


def delete_group(db: Session, group_id: int) -> None:
    group = get_group(db, group_id)
    db.delete(group)
    db.commit()