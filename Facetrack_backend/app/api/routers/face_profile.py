from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin
from app.core.permissions import is_admin
from app.models.user import User
from app.schemas.face_profile import FaceProfileCreate, FaceProfileOut
from app.services import face_profile_service
from app.services.audit_service import record_audit

router = APIRouter(prefix="/face-profiles", tags=["Face Profiles"])


@router.post("/", response_model=FaceProfileOut)
def create_face_profile(
    user_id: int,
    data: FaceProfileCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Face enrollment is personal: you can only register YOUR OWN face.
    # (Letting someone enroll a face for another account would defeat the
    # whole point of preventing buddy-punching.)
    if user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only register your own face")
    return face_profile_service.create_face_profile(db, current_user.id, data)


@router.get("/user/{user_id}", response_model=list[FaceProfileOut])
def get_face_profiles_by_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Biometric data: only the owner or an admin.
    if user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You do not have permission to access this data")
    return face_profile_service.get_face_profiles_by_user(db, user_id)


@router.delete("/user/{user_id}")
def reset_face_profiles(
    user_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    """Admin only: delete a person's saved faces so they can register again
    (new phone, bad first registration, wrong person registered)."""
    removed = face_profile_service.delete_face_profiles(db, user_id)
    record_audit(db, request, admin, "delete", "face_profiles", user_id, {"removed": removed})
    return {"removed": removed}