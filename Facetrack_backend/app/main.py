from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routers import face_profile, group
from app.api.routers import auth  , schedule ,attendance ,leave_request ,correction_request ,notification ,audit_log  ,user
from app.api.routers import location
from app.api.routers import role , face_profile

import asyncio
from contextlib import asynccontextmanager

from app.core.database import SessionLocal
from app.services.absence_service import mark_absences

app = FastAPI(title="AttendFace API")



app.add_middleware(
    CORSMiddleware,           # the actual security-rule component being added
    allow_origins=["*"],      # "*" = allow requests from ANY address (fine for development, not for production)
    allow_credentials=True,   # allow cookies/auth headers to be sent along with requests
    allow_methods=["*"],      # allow GET, POST, PUT, DELETE, etc. — all of them
    allow_headers=["*"],      # allow any custom header the client sends (like your Authorization: Bearer token)
)


app.include_router(auth.router)
app.include_router(face_profile.router)
app.include_router(group.router)
app.include_router(location.router)
app.include_router(schedule.router)
app.include_router(attendance.router)
app.include_router(leave_request.router)
app.include_router(correction_request.router)
app.include_router(notification.router)
app.include_router(audit_log.router)
app.include_router(user.router)
app.include_router(role.router)
app.include_router(face_profile.router)

@app.get("/")
def read_root():
    return {"message": "AttendFace API is running"}



def _run_absence_job():
    db = SessionLocal()
    try:
        mark_absences(db)
    finally:
        db.close()


async def _absence_loop():
    while True:
        try:
            await asyncio.to_thread(_run_absence_job)
        except Exception as e:
            print("absence job failed:", e)
        await asyncio.sleep(600)  # every 10 minutes


@asynccontextmanager
async def lifespan(app):
    task = asyncio.create_task(_absence_loop())
    yield
    task.cancel()