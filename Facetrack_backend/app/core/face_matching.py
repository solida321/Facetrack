import math
import os


def cosine_similarity(a: list[float], b: list[float]) -> float:
    """Returns a value from -1.0 to 1.0 — same scale as the Flutter
    package's compareFaces(). Higher means more similar.
    """
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(y * y for y in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


# Check-in must be STRICT: letting a wrong person in is worse than asking a right
# person to scan again. Change it without editing code: FACE_MATCH_THRESHOLD=0.75
MATCH_THRESHOLD = float(os.getenv("FACE_MATCH_THRESHOLD", "0.7"))

# Registration only asks "is this face already used by another account?",
# so it keeps the older, looser cutoff on purpose (it catches more duplicates).
DUPLICATE_THRESHOLD = 0.6


def best_match_score(new_embedding: list[float], stored_embeddings: list[list[float]]) -> float:
    """Compares the new embedding against every stored one and returns
    the single best (highest) similarity score found.
    """
    if not stored_embeddings:
        return -1.0
    return max(cosine_similarity(new_embedding, stored) for stored in stored_embeddings)


def is_match(new_embedding: list[float], stored_embeddings: list[list[float]]) -> bool:
    return best_match_score(new_embedding, stored_embeddings) >= MATCH_THRESHOLD