from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.role import Role
from app.models.user import User
from app.schemas.user import RoleOut

router = APIRouter(prefix="/roles", tags=["Roles"])


@router.get("/", response_model=list[RoleOut])
def list_roles(db: Session = Depends(get_db), _user: User = Depends(get_current_user)):
    return db.query(Role).all()