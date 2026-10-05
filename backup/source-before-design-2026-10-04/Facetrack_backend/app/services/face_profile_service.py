from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.face_profile import FaceProfile
from app.schemas.face_profile import FaceProfileCreate
from app.core.face_matching import best_match_score, MATCH_THRESHOLD, cosine_similarity

def create_face_profile(db: Session, user_id: int, data: FaceProfileCreate) -> FaceProfile:
    duplicate_user_id = find_duplicate_face(db, data.embedding, exclude_user_id=user_id)
    if duplicate_user_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This face is already registered to another account.",
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

    stored_embeddings = [p.embedding for p in profiles]
    score = best_match_score(new_embedding, stored_embeddings)
    return score >= MATCH_THRESHOLD, score


def find_duplicate_face(db: Session, new_embedding: list[float], exclude_user_id: int) -> int | None:
    """Checks if this embedding matches ANY other user's registered face.
    Returns the matching user's id if found, None otherwise.
    """
    all_profiles = db.query(FaceProfile).filter(FaceProfile.user_id != exclude_user_id).all()
    if not all_profiles:
        return None

    for profile in all_profiles:
        score = cosine_similarity(new_embedding, profile.embedding)
        if score >= MATCH_THRESHOLD:
            return profile.user_id
    return None