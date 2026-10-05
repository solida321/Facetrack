from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.user import UserOut, UserUpdate
from app.services import user_service
from app.schemas.user import UserCreateByAdmin

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserOut)
def get_my_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.get("/", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db)):
    return user_service.get_all_users(db)


@router.put("/{user_id}", response_model=UserOut)
def update_user(user_id: int, data: UserUpdate, db: Session = Depends(get_db)):
    return user_service.update_user(db, user_id, data)


@router.post("/", response_model=UserOut)
def create_user(data: UserCreateByAdmin, db: Session = Depends(get_db)):
    return user_service.create_user_by_admin(db, data)


@router.delete("/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    user_service.delete_user(db, user_id)
    return {"detail": "User deleted"}     

@router.put("/{user_id}", response_model=UserOut)
def update_user(user_id: int, data: UserUpdate, actor_id: int | None = None, db: Session = Depends(get_db)):
    return user_service.update_user(db, user_id, data, actor_id)