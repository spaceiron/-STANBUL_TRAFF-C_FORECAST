"""Curated and interpolated route geometry for map polylines."""
import json
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, 'data', 'route_stops.json')

_CURATED = None

# start_lat, start_lng, end_lat, end_lng — used when curated stops are missing.
ROUTE_ENDPOINTS = {
    'M1A': (41.005556, 28.952222, 40.976944, 28.814167),
    'M2': (41.005556, 28.952222, 41.125, 29.046667),
    'M3': (41.016667, 28.776667, 41.074444, 28.766667),
    'M4': (40.990278, 29.022222, 40.898611, 29.309167),
    'M5': (41.021667, 29.015833, 41.038333, 29.278333),
    'M6': (41.081111, 28.993333, 41.085556, 29.045556),
    'M7': (41.056667, 28.826667, 41.063333, 28.992778),
    'M9': (40.975, 28.835, 41.062, 28.801),
    'M11': (41.0675, 28.9975, 41.276944, 28.727222),
    'MARMARAY': (41.012, 28.735, 40.802778, 29.430556),
    '34B': (41.021111, 28.721111, 40.990278, 29.022222),
    '34BZ': (41.021111, 28.721111, 41.067222, 29.000833),
    'T1': (41.034722, 28.993611, 41.039722, 28.858611),
    'T5': (41.076, 28.935, 41.0174, 28.9706),
    '500T': (41.039722, 28.858611, 41.078472, 29.093056),
    'E1': (41.005556, 28.952222, 41.076, 28.935),
    'E2': (41.078472, 29.093056, 40.990278, 29.022222),
    'E3': (41.021667, 29.015833, 41.026, 29.124),
    'E4': (41.036944, 28.985, 41.042222, 29.006944),
    'E5': (40.990278, 29.022222, 41.078472, 29.093056),
    '35': (41.0174, 28.9706, 41.039722, 28.858611),
    '38E': (41.0174, 28.9706, 41.008333, 28.64),
    '43': (41.009722, 28.937222, 41.018611, 28.885833),
    '45': (41.0174, 28.9706, 41.058333, 28.878333),
    '47': (41.036944, 28.985, 41.166111, 29.056944),
    '50': (41.0174, 28.9706, 41.059722, 28.941389),
    '61': (41.036944, 28.985, 41.042222, 29.006944),
    '66': (41.036944, 28.985, 41.166111, 29.056944),
    '73': (41.0174, 28.9706, 41.108333, 28.658333),
    '80': (41.0174, 28.9706, 41.048333, 28.778333),
    '11': (41.021667, 29.015833, 41.125, 29.083333),
    '12': (41.021667, 29.015833, 41.026, 29.124),
    '14': (40.990278, 29.022222, 41.0175, 29.23),
    '15': (41.021667, 29.015833, 41.078472, 29.093056),
    '17': (40.990278, 29.022222, 41.014722, 29.206667),
    '19': (41.021667, 29.015833, 41.038333, 29.278333),
    '22': (40.990278, 29.022222, 41.001111, 29.124444),
    '25': (41.021667, 29.015833, 41.125, 29.083333),
    '28': (41.042222, 29.006944, 41.166111, 29.056944),
    '30': (40.990278, 29.022222, 41.006389, 29.136667),
    '32': (41.021667, 29.015833, 41.008333, 29.265),
    '34': (40.990278, 29.022222, 41.014722, 29.206667),
    '36': (41.021667, 29.015833, 41.001111, 29.124444),
    '38': (40.990278, 29.022222, 41.0175, 29.23),
    'F1': (41.0174, 28.9706, 41.038889, 28.940556),
    'F2': (41.0174, 28.9706, 41.048611, 28.933889),
}


def _load_curated():
    global _CURATED
    if _CURATED is not None:
        return _CURATED
    try:
        with open(DATA_PATH, encoding='utf-8') as f:
            raw = json.load(f)
        _CURATED = {k.upper(): v for k, v in raw.items()}
    except (OSError, json.JSONDecodeError):
        _CURATED = {}
    return _CURATED


def get_curated_stops(route_id):
    route_id = route_id.upper().strip()
    return _load_curated().get(route_id)


def interpolate_stops(route_id, stop_count=10):
    route_id = route_id.upper().strip()
    endpoints = ROUTE_ENDPOINTS.get(route_id)
    if not endpoints:
        return None

    start_lat, start_lng, end_lat, end_lng = endpoints
    points = []
    for i in range(stop_count):
        t = i / max(stop_count - 1, 1)
        lat = start_lat + (end_lat - start_lat) * t
        lng = start_lng + (end_lng - start_lng) * t
        points.append({
            'id': f'{route_id}_{i + 1}',
            'name': f'{route_id} Stop {i + 1}',
            'lat': round(lat, 6),
            'lng': round(lng, 6),
        })
    return points


def build_route_stops(route_id):
    """Return best available stop list for map geometry."""
    route_id = route_id.upper().strip()
    curated = get_curated_stops(route_id)
    if curated:
        return [dict(s) for s in curated]

    interpolated = interpolate_stops(route_id)
    if interpolated:
        return interpolated

    return None
