from datetime import date

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routers import face_profile, group
from app.api.routers import auth, schedule, attendance, leave_request, correction_request, notification, audit_log, user
from app.api.routers import location
from app.api.routers import role
from app.api.routers import report
from datetime import date

import asyncio
from contextlib import asynccontextmanager

from app.core.database import SessionLocal
from app.services.absence_service import mark_absences, mark_missing_checkouts



# Day the real system started. Nothing before this day is marked absent.
ABSENCE_START_DATE = date(2026, 10, 1)


def _run_absence_job():
    db = SessionLocal()
    try:
        # Go back to the start date, so days missed while the server was off are filled in.
        days_back = (date.today() - ABSENCE_START_DATE).days + 1
        mark_absences(db, days_back=max(days_back, 2))
        mark_missing_checkouts(db)
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


app = FastAPI(title="AttendFace API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # fine for development, not for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
app.include_router(report.router)

@app.get("/")
def read_root():
    return {"message": "AttendFace API is running"} 