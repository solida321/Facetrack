from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.role import Role
from app.schemas.user import RoleOut

router = APIRouter(prefix="/roles", tags=["Roles"])


@router.get("/", response_model=list[RoleOut])
def list_roles(db: Session = Depends(get_db)):
    return db.query(Role).all()