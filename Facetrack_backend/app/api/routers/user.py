from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin, require_staff
from app.core.permissions import is_admin
from app.models.user import User
from app.schemas.user import UserOut, UserUpdate
from app.services import user_service
from app.services.audit_service import record_audit
from app.schemas.user import UserCreateByAdmin
from app.core.security import hash_password, verify_password
from app.schemas.user import PasswordChange




router = APIRouter(prefix="/users", tags=["Users"])

# Fields a normal user may change on their OWN profile.
# role_id / status / group_id are admin-only, otherwise anyone could promote themselves.
SELF_EDITABLE_FIELDS = {"full_name", "phone", "gender"}


@router.get("/me", response_model=UserOut)
def get_my_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.get("/", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db), current_user: User = Depends(require_staff)):
    # admin -> everyone, manager -> only their own group
    return user_service.get_all_users(db, current_user)


@router.post("/", response_model=UserOut)
def create_user(
    data: UserCreateByAdmin,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    user = user_service.create_user_by_admin(db, data)
    record_audit(db, request, admin, "create", "users", user.id,
                 {"email": user.email, "role_id": user.role_id, "group_id": user.group_id})
    return user


@router.put("/{user_id}", response_model=UserOut)
def update_user(
    user_id: int,
    data: UserUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    changes = data.model_dump(exclude_unset=True)

    if not is_admin(current_user):
        if user_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only edit your own profile")
        forbidden = set(changes) - SELF_EDITABLE_FIELDS
        if forbidden:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only an admin can change: " + ", ".join(sorted(forbidden)),
            )

    user = user_service.update_user(db, user_id, data)
    record_audit(db, request, current_user, "update", "users", user.id, {"changed": changes})
    return user


@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    request: Request,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    if user_id == admin.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You cannot delete your own account")
    user_service.delete_user(db, user_id)
    record_audit(db, request, admin, "delete", "users", user_id)
    return {"detail": "User deleted"}


@router.put("/me/password")
def change_my_password(
    data: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(data.old_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    if data.old_password == data.new_password:
        raise HTTPException(status_code=400, detail="New password must be different from the current one")

    current_user.password_hash = hash_password(data.new_password)
    db.commit()
    return {"message": "Password updated"}