# app/api/routers/location.py
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.models.user import User
from app.schemas.location import LocationCreate, LocationUpdate, LocationOut
from app.services import location_service
from app.services.audit_service import record_audit

router = APIRouter(prefix="/locations", tags=["Locations"])


@router.post("/", response_model=LocationOut)
def create_location(
    data: LocationCreate,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    location = location_service.create_location(db, data)
    record_audit(db, request, admin, "create", "locations", location.id,
                 {"name": location.name, "radius": location.allowed_radius_meters})
    return location


@router.get("/", response_model=list[LocationOut])
def list_locations(db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    return location_service.get_all_locations(db)


@router.get("/{location_id}", response_model=LocationOut)
def get_location(location_id: int, db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    return location_service.get_location(db, location_id)


@router.put("/{location_id}", response_model=LocationOut)
def update_location(
    location_id: int,
    data: LocationUpdate,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    location = location_service.update_location(db, location_id, data)
    record_audit(db, request, admin, "update", "locations", location_id, {"changed": data.model_dump(exclude_unset=True)})
    return location


@router.delete("/{location_id}")
def delete_location(
    location_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    location_service.delete_location(db, location_id)
    record_audit(db, request, admin, "delete", "locations", location_id)
    return {"detail": "Location deleted"}
