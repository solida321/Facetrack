import logging
import os
import time

from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.face_profile import FaceProfile
from app.schemas.face_profile import FaceProfileCreate
from app.core.face_matching import best_match_score, MATCH_THRESHOLD, DUPLICATE_THRESHOLD, cosine_similarity

logger = logging.getLogger("uvicorn.error")

# New registration photos must look like the same person as the photos already saved.
# (Side angles score lower than front-to-front, so this is looser than check-in.)
REGISTER_CONSISTENCY = float(os.getenv("FACE_REGISTER_CONSISTENCY", "0.4"))

# Too many failed scans in a row -> pause. Stops "try again and again" guessing.
MAX_FAILED_SCANS = int(os.getenv("FACE_MAX_FAILED_SCANS", "5"))
LOCK_WINDOW_SECONDS = int(os.getenv("FACE_LOCK_WINDOW_SECONDS", "600"))
_failed_scans: dict[int, list[float]] = {}  # user id -> times of recent failures


def _recent_failures(user_id: int) -> list[float]:
    now = time.time()
    recent = [t for t in _failed_scans.get(user_id, []) if now - t < LOCK_WINDOW_SECONDS]
    _failed_scans[user_id] = recent
    return recent


def is_consistent_with(new_embedding: list[float], others: list[list[float]]) -> bool:
    """True when there is nothing to compare with, or the new face matches at least one."""
    if not others:
        return True
    return best_match_score(new_embedding, others) >= REGISTER_CONSISTENCY


def create_face_profile(db: Session, user_id: int, data: FaceProfileCreate) -> FaceProfile:
    duplicate_user_id = find_duplicate_face(db, data.embedding, exclude_user_id=user_id)
    if duplicate_user_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This face is already registered to another account.",
        )

    # The new photo must look like the photos this person already registered.
    # Without this, anyone logged in could swap in another person's face.
    other_angles = db.query(FaceProfile).filter(
        FaceProfile.user_id == user_id,
        FaceProfile.angle != data.angle,
    ).all()
    if not is_consistent_with(data.embedding, [p.embedding for p in other_angles]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This photo does not look like your earlier photos. Please use the same face for all angles.",
        )

    existing = db.query(FaceProfile).filter(
        FaceProfile.user_id == user_id,
        FaceProfile.angle == data.angle,
    ).first()

    if existing:
        existing.embedding = data.embedding
        db.commit()
        db.refresh(existing)
        return existing

    profile = FaceProfile(user_id=user_id, angle=data.angle, embedding=data.embedding)
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


def get_face_profiles_by_user(db: Session, user_id: int) -> list[FaceProfile]:
    return db.query(FaceProfile).filter(FaceProfile.user_id == user_id).all()


def verify_face(db: Session, user_id: int, new_embedding: list[float]) -> tuple[bool, float]:
    """Returns (is_match, score) — used by attendance_service at check-in time."""
    profiles = get_face_profiles_by_user(db, user_id)
    if not profiles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No registered face found for this user. Please complete face registration first.",
        )

    if len(_recent_failures(user_id)) >= MAX_FAILED_SCANS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many failed face scans. Please wait a few minutes and try again.",
        )

    stored_embeddings = [p.embedding for p in profiles]
    score = best_match_score(new_embedding, stored_embeddings)
    # Write the score in the server log so you can measure real numbers:
    # same person vs different person, then choose the threshold from data.
    logger.info("face verify user=%s score=%.3f threshold=%.2f", user_id, score, MATCH_THRESHOLD)
    matched = score >= MATCH_THRESHOLD
    if matched:
        _failed_scans.pop(user_id, None)  # a good scan clears the counter
    else:
        _failed_scans.setdefault(user_id, []).append(time.time())
    return matched, score


def delete_face_profiles(db: Session, user_id: int) -> int:
    """Admin reset: removes every saved angle so the person can register again."""
    removed = db.query(FaceProfile).filter(FaceProfile.user_id == user_id).delete()
    db.commit()
    _failed_scans.pop(user_id, None)
    return removed


def find_duplicate_face(db: Session, new_embedding: list[float], exclude_user_id: int) -> int | None:
    """Checks if this embedding matches ANY other user's registered face.
    Returns the matching user's id if found, None otherwise.
    """
    all_profiles = db.query(FaceProfile).filter(FaceProfile.user_id != exclude_user_id).all()
    if not all_profiles:
        return None

    for profile in all_profiles:
        score = cosine_similarity(new_embedding, profile.embedding)
        if score >= DUPLICATE_THRESHOLD:
            return profile.user_id
    return None