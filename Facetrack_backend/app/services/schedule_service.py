from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.schedule import Schedule
from app.schemas.schedule import ScheduleCreate, ScheduleUpdate
from app.models.location import Location


def _ensure_location_exists(db: Session, location_id: int) -> None:
    if not db.query(Location.id).filter(Location.id == location_id).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Location not found")

def create_schedule(db: Session, data: ScheduleCreate) -> Schedule:
    _ensure_location_exists(db, data.location_id)
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
    changes = data.model_dump(exclude_unset=True)
    if "location_id" in changes:
        if changes["location_id"] is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A location is required")
        _ensure_location_exists(db, changes["location_id"])
    for field, value in changes.items():
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