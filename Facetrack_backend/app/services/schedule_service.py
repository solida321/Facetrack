from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.schedule import Schedule
from app.schemas.schedule import ScheduleCreate, ScheduleUpdate


def create_schedule(db: Session, data: ScheduleCreate) -> Schedule:
    schedule = Schedule(**data.model_dump())
    db.add(schedule)
    db.commit()
    db.refresh(schedule)
    return schedule


def get_schedule(db: Session, schedule_id: int) -> Schedule:
    schedule = db.query(Schedule).filter(Schedule.id == schedule_id, Schedule.is_active.is_(True)).first()
    if not schedule:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Schedule not found")
    return schedule


def get_all_schedules(db: Session) -> list[Schedule]:
    return db.query(Schedule).filter(Schedule.is_active.is_(True)).all()


def get_schedules_by_group(db: Session, group_id: int) -> list[Schedule]:
    return db.query(Schedule).filter(Schedule.group_id == group_id, Schedule.is_active.is_(True)).all()


def update_schedule(db: Session, schedule_id: int, data: ScheduleUpdate) -> Schedule:
    schedule = get_schedule(db, schedule_id)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(schedule, field, value)
    db.commit()
    db.refresh(schedule)
    return schedule


def delete_schedule(db: Session, schedule_id: int) -> None:
    """Archives instead of deleting, so past attendance records keep a
    schedule to point at."""
    schedule = get_schedule(db, schedule_id)
    schedule.is_active = False
    db.commit()