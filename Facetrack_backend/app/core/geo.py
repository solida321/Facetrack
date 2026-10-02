# app/core/geo.py
import math


def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Returns the distance in meters between two GPS coordinates,
    using the Haversine formula (accounts for Earth's curvature).
    """
    R = 6371000  # Earth's radius in meters

    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)

    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


def is_within_allowed_radius(user_lat: float, user_lon: float, location) -> bool:
    """Checks whether a user's GPS coordinates fall within a location's
    allowed_radius_meters. `location` must be a Location model instance
    with .latitude, .longitude, .allowed_radius_meters.
    """
    distance = haversine_distance_meters(
        user_lat, user_lon,
        float(location.latitude), float(location.longitude)
    )
    return distance <= location.allowed_radius_meters