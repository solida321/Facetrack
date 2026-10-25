# app/api/routers/schedule.py
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.core.permissions import ensure_can_access_group
from app.models.user import User
from app.schemas.schedule import ScheduleCreate, ScheduleUpdate, ScheduleOut
from app.services import schedule_service
from app.services.audit_service import record_audit

router = APIRouter(prefix="/schedules", tags=["Schedules"])


@router.post("/", response_model=ScheduleOut)
def create_schedule(
    data: ScheduleCreate,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    schedule = schedule_service.create_schedule(db, data)
    record_audit(db, request, admin, "create", "schedules", schedule.id,
                 {"group_id": schedule.group_id, "session_name": schedule.session_name,
                  "day_of_week": schedule.day_of_week, "location_id": schedule.location_id})
    return schedule


@router.get("/", response_model=list[ScheduleOut])
def list_schedules(db: Session = Depends(get_db), _admin: User = Depends(require_admin)):
    return schedule_service.get_all_schedules(db)


@router.get("/group/{group_id}", response_model=list[ScheduleOut])
def get_schedules_by_group(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Admin can look at any group; everyone else only at their own.
    ensure_can_access_group(current_user, group_id)
    return schedule_service.get_schedules_by_group(db, group_id)


@router.get("/{schedule_id}", response_model=ScheduleOut)
def get_schedule(
    schedule_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    schedule = schedule_service.get_schedule(db, schedule_id)
    ensure_can_access_group(current_user, schedule.group_id)
    return schedule


@router.put("/{schedule_id}", response_model=ScheduleOut)
def update_schedule(
    schedule_id: int,
    data: ScheduleUpdate,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    schedule = schedule_service.update_schedule(db, schedule_id, data)
    record_audit(db, request, admin, "update", "schedules", schedule_id,
                 {"changed": data.model_dump(exclude_unset=True, mode="json")})
    return schedule


@router.delete("/{schedule_id}")
def delete_schedule(
    schedule_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    schedule_service.delete_schedule(db, schedule_id)
    record_audit(db, request, admin, "delete", "schedules", schedule_id)
    return {"detail": "Schedule deleted"}
