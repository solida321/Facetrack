# app/api/routers/schedule.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.schedule import ScheduleCreate, ScheduleUpdate, ScheduleOut
from app.services import schedule_service

router = APIRouter(prefix="/schedules", tags=["Schedules"])


@router.post("/", response_model=ScheduleOut)
def create_schedule(data: ScheduleCreate, db: Session = Depends(get_db)):
    return schedule_service.create_schedule(db, data)


@router.get("/", response_model=list[ScheduleOut])
def list_schedules(db: Session = Depends(get_db)):
    return schedule_service.get_all_schedules(db)


@router.get("/{schedule_id}", response_model=ScheduleOut)
def get_schedule(schedule_id: int, db: Session = Depends(get_db)):
    return schedule_service.get_schedule(db, schedule_id)


@router.get("/group/{group_id}", response_model=list[ScheduleOut])
def get_schedules_by_group(group_id: int, db: Session = Depends(get_db)):
    return schedule_service.get_schedules_by_group(db, group_id)


@router.put("/{schedule_id}", response_model=ScheduleOut)
def update_schedule(schedule_id: int, data: ScheduleUpdate, db: Session = Depends(get_db)):
    return schedule_service.update_schedule(db, schedule_id, data)


@router.delete("/{schedule_id}")
def delete_schedule(schedule_id: int, db: Session = Depends(get_db)):
    schedule_service.delete_schedule(db, schedule_id)
    return {"detail": "Schedule deleted"}