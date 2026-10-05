# app/services/location_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.location import Location
from app.schemas.location import LocationCreate, LocationUpdate


def create_location(db: Session, data: LocationCreate) -> Location:
    location = Location(**data.model_dump())
    db.add(location)
    db.commit()
    db.refresh(location)
    return location


def get_location(db: Session, location_id: int) -> Location:
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")
    return location


def get_all_locations(db: Session) -> list[Location]:
    return db.query(Location).all()


def update_location(db: Session, location_id: int, data: LocationUpdate) -> Location:
    location = get_location(db, location_id)
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(location, field, value)
    db.commit()
    db.refresh(location)
    return location


def delete_location(db: Session, location_id: int) -> None:
    location = get_location(db, location_id)
    db.delete(location)
    db.commit()