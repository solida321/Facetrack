# Importing every model here means one "from app.models import *"
# (used in alembic/env.py) registers all of them with Base.metadata —
# required for Alembic's autogenerate to see them. Add each new model
# file to this list as you create it.
from app.models.role import Role  # noqa: F401
from app.models.user import User  # noqa: F401
from app.models.face_profile import FaceProfile  # noqa: F401