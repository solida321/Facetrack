# app/api/routers/location.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.location import LocationCreate, LocationUpdate, LocationOut
from app.services import location_service

router = APIRouter(prefix="/locations", tags=["Locations"])


@router.post("/", response_model=LocationOut)
def create_location(data: LocationCreate, db: Session = Depends(get_db)):
    return location_service.create_location(db, data)


@router.get("/", response_model=list[LocationOut])
def list_locations(db: Session = Depends(get_db)):
    return location_service.get_all_locations(db)


@router.get("/{location_id}", response_model=LocationOut)
def get_location(location_id: int, db: Session = Depends(get_db)):
    return location_service.get_location(db, location_id)


@router.put("/{location_id}", response_model=LocationOut)
def update_location(location_id: int, data: LocationUpdate, db: Session = Depends(get_db)):
    return location_service.update_location(db, location_id, data)


@router.delete("/{location_id}")
def delete_location(location_id: int, db: Session = Depends(get_db)):
    location_service.delete_location(db, location_id)
    return {"detail": "Location deleted"}