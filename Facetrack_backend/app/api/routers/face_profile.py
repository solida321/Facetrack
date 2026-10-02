from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.face_profile import FaceProfileCreate, FaceProfileOut
from app.services import face_profile_service

router = APIRouter(prefix="/face-profiles", tags=["Face Profiles"])


@router.post("/", response_model=FaceProfileOut)
def create_face_profile(user_id: int, data: FaceProfileCreate, db: Session = Depends(get_db)):
    return face_profile_service.create_face_profile(db, user_id, data)


@router.get("/user/{user_id}", response_model=list[FaceProfileOut])
def get_face_profiles_by_user(user_id: int, db: Session = Depends(get_db)):
    return face_profile_service.get_face_profiles_by_user(db, user_id)