import os, json, numpy as np
from datetime import datetime, timedelta
from flask import Flask, jsonify, request
import joblib
import urllib.parse
import urllib.request

app = Flask(__name__)
USER_REPORTS = {}
LIVE_DATA_LAST_ERROR = None

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model  = joblib.load(os.path.join(BASE_DIR, 'density_model_rf.pkl'))
scaler = joblib.load(os.path.join(BASE_DIR, 'scaler_rf.pkl'))
with open(os.path.join(BASE_DIR, 'model_meta.json')) as f:
    MODEL_META = json.load(f)

ROUTE_CENTERS = {
    # METROBÜS
    '34B':  (41.0090, 28.9340),
    '34BZ': (41.0090, 28.9340),
    # METRO
    'M1A':  (41.0082, 28.8953),
    'M1B':  (41.0082, 28.8953),
    'M2':   (41.0694, 29.0098),
    'M3':   (41.0694, 28.7953),
    'M4':   (40.9761, 29.1048),
    'M5':   (41.0194, 29.0298),
    'M6':   (41.0794, 29.0298),
    'M7':   (41.0894, 28.8953),
    'M9':   (41.0082, 28.7953),
    'M11':  (41.2694, 28.7253),
    # MARMARAY
    'MARMARAY': (41.0136, 29.0547),
    # TRAMVAY
    'T1':   (41.0082, 28.9784),
    'T5':   (41.0294, 28.9584),
    # OTOBÜS - ANADOLU
    '11':   (41.0250, 29.0650),
    '11A':  (41.0250, 29.0650),
    '12':   (41.0150, 29.0450),
    '13':   (41.0350, 29.0750),
    '14':   (40.9961, 29.1548),
    '15':   (41.0250, 28.9650),
    '15A':  (41.0150, 29.0350),
    '15F':  (41.0450, 29.1050),
    '15S':  (41.0350, 29.0850),
    '16':   (40.9761, 29.0248),
    '17':   (40.9861, 29.0548),
    '18':   (40.9961, 29.0748),
    '19':   (41.0061, 29.0948),
    '20':   (41.0161, 29.1148),
    '22':   (41.0261, 29.1348),
    '25':   (41.0461, 29.0648),
    '28':   (41.0561, 29.0248),
    '30':   (40.9661, 29.0048),
    '32':   (40.9761, 29.0448),
    '34':   (40.9861, 29.0648),
    '36':   (40.9961, 29.0848),
    '38':   (41.0061, 29.1048),
    '40':   (41.0161, 29.1248),
    # OTOBÜS - AVRUPA
    '35':   (41.0082, 28.9784),
    '35A':  (41.0182, 28.9584),
    '38E':  (41.0282, 28.9384),
    '43':   (41.0382, 28.9184),
    '44':   (41.0482, 28.8984),
    '45':   (41.0582, 28.8784),
    '46':   (41.0682, 28.8584),
    '47':   (41.0782, 28.8384),
    '48':   (41.0882, 28.8184),
    '49':   (41.0982, 28.7984),
    '50':   (41.0082, 28.8784),
    '54':   (41.0182, 28.8584),
    '56':   (41.0282, 28.8384),
    '58':   (41.0382, 28.8184),
    '61':   (41.0482, 28.7984),
    '63':   (41.0582, 28.7784),
    '65':   (41.0682, 28.7584),
    '66':   (41.0782, 28.7384),
    '67':   (41.0882, 28.7184),
    '68':   (41.0982, 28.6984),
    '69':   (41.1082, 28.6784),
    '71':   (41.1182, 28.6584),
    '73':   (41.0082, 28.8584),
    '74':   (41.0182, 28.8384),
    '76':   (41.0282, 28.8184),
    '78':   (41.0382, 28.7984),
    '80':   (41.0482, 28.7784),
    '81':   (41.0582, 28.7584),
    '82':   (41.0682, 28.7384),
    '83':   (41.0782, 28.7184),
    '84':   (41.0882, 28.6984),
    '85':   (41.0982, 28.6784),
    '87':   (41.1082, 28.6584),
    '88':   (41.1182, 28.6384),
    '89':   (41.1282, 28.6184),
    '91':   (41.0082, 28.8384),
    '93':   (41.0182, 28.8184),
    '95':   (41.0282, 28.7984),
    '97':   (41.0382, 28.7784),
    '99':   (41.0482, 28.7584),
    # EKSPRES HATLAR
    '500T': (41.0082, 28.9784),
    'E1':   (41.0082, 28.9584),
    'E2':   (40.9960, 29.0280),
    'E3':   (41.0182, 28.9384),
    'E4':   (41.0282, 28.9184),
    'E5':   (41.0382, 28.8984),
    'E6':   (41.0482, 28.8784),
    'E10':  (41.0582, 28.8584),
    'E11':  (41.0682, 28.8384),
    'E12':  (41.0782, 28.8184),
    'E13':  (41.0882, 28.7984),
    'E14':  (41.0982, 28.7784),
    # HIZLI OTOBÜS
    'EXP1': (41.0082, 28.9784),
    'EXP2': (41.0182, 28.9584),
    # FERİBOT / VAPUR
    'F1':   (41.0082, 29.0084),
    'F2':   (41.0182, 29.0284),
    'F3':   (41.0282, 29.0484),
    # TELEFERIK
    'TF1':  (41.0582, 29.0584),
    'TF2':  (41.0682, 29.0684),
}

def build_features(lat, lng, avg_speed, at_time=None):
    t = (at_time or datetime.utcnow()) + timedelta(hours=3)
    hour = t.hour; weekday = t.weekday(); day = t.day
    speed_norm = min(avg_speed / 180.0, 1.0)
    return np.array([[
        hour, weekday, day,
        int(weekday >= 5),
        int(7 <= hour <= 9),
        int(17 <= hour <= 20),
        int(11 <= hour <= 14),
        int(hour >= 23 or hour <= 5),
        np.sin(2*np.pi*hour/24), np.cos(2*np.pi*hour/24),
        np.sin(2*np.pi*weekday/7), np.cos(2*np.pi*weekday/7),
        lat, lng, speed_norm,
    ]])

def predict_density(lat, lng, avg_speed=50.0, at_time=None):
    X = build_features(lat, lng, avg_speed, at_time)
    return float(np.clip(model.predict(scaler.transform(X))[0], 0.0, 1.0))

def score_label(score):
    pct = int(score * 100)
    if score < 0.33: return f'%{pct} Bos'
    if score < 0.66: return f'%{pct} Orta Yogun'
    return f'%{pct} Dolu'


def confidence_label(score):
    pct = int(score * 100)
    if score < 0.50:
        return f'%{pct} Dusuk Guven'
    if score < 0.75:
        return f'%{pct} Orta Guven'
    return f'%{pct} Yuksek Guven'

def mock_buses(route_id):
    import random
    c = ROUTE_CENTERS.get(route_id, (41.0082, 28.9784))
    return [
        {'plate': f'34 TF {random.randint(100,999)}',
         'lat': c[0]+random.uniform(-0.03,0.03),
         'lng': c[1]+random.uniform(-0.03,0.03),
         'speed': random.uniform(15,70)}
        for _ in range(random.randint(4,10))
    ]


def _normalize_vehicles_payload(payload):
    if isinstance(payload, list):
        return payload
    if not isinstance(payload, dict):
        return []
    for key in ['vehicles', 'data', 'result', 'items', 'records']:
        value = payload.get(key)
        if isinstance(value, list):
            return value
        if isinstance(value, dict):
            for nested_key in ['vehicles', 'data', 'items', 'records']:
                nested = value.get(nested_key)
                if isinstance(nested, list):
                    return nested
    return []


def _extract_value(item, keys):
    for key in keys:
        if key in item and item[key] not in (None, ''):
            return item[key]
    return None


def _normalize_live_buses(route_id, payload):
    route_id = route_id.upper().strip()
    rows = _normalize_vehicles_payload(payload)
    normalized = []
    for row in rows:
        if not isinstance(row, dict):
            continue

        row_route = str(_extract_value(row, [
            'routeId', 'route_id', 'line', 'lineCode', 'hat_kodu', 'hat'
        ]) or '').upper().strip()
        if row_route and row_route != route_id:
            continue

        lat_raw = _extract_value(row, ['lat', 'latitude', 'enlem', 'y'])
        lng_raw = _extract_value(row, ['lng', 'lon', 'longitude', 'boylam', 'x'])
        if lat_raw is None or lng_raw is None:
            continue

        try:
            lat = float(lat_raw)
            lng = float(lng_raw)
            speed = float(_extract_value(row, ['speed', 'velocity', 'hiz', 'kmh']) or 35.0)
        except (TypeError, ValueError):
            continue

        plate = str(_extract_value(row, [
            'plate', 'vehicleId', 'vehicle_id', 'arac_no', 'kapiNo', 'id'
        ]) or f'{route_id}_live_{len(normalized)+1}')
        normalized.append({
            'plate': plate,
            'lat': lat,
            'lng': lng,
            'speed': speed,
        })
    return normalized


def fetch_live_buses(route_id):
    global LIVE_DATA_LAST_ERROR
    api_url = os.getenv('IBB_TRAFFIC_API_URL', '').strip()
    if not api_url:
        return None

    api_key = os.getenv('IBB_API_KEY', '').strip()
    key_header = os.getenv('IBB_API_KEY_HEADER', 'apikey').strip()
    route_param = os.getenv('IBB_ROUTE_PARAM', 'routeId').strip()
    timeout_sec = float(os.getenv('IBB_TIMEOUT_SEC', '4'))

    try:
        parsed = urllib.parse.urlparse(api_url)
        query = urllib.parse.parse_qs(parsed.query)
        query[route_param] = [route_id]
        query.setdefault('limit', ['200'])
        final_query = urllib.parse.urlencode(query, doseq=True)
        final_url = urllib.parse.urlunparse((
            parsed.scheme, parsed.netloc, parsed.path,
            parsed.params, final_query, parsed.fragment
        ))

        req = urllib.request.Request(final_url)
        if api_key:
            req.add_header(key_header, api_key)
        req.add_header('Accept', 'application/json')

        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            if resp.status != 200:
                LIVE_DATA_LAST_ERROR = f'HTTP {resp.status}'
                return None
            body = resp.read().decode('utf-8')
            payload = json.loads(body)

        buses = _normalize_live_buses(route_id, payload)
        if not buses:
            LIVE_DATA_LAST_ERROR = 'Live payload parsed but no matching vehicles'
            return None
        LIVE_DATA_LAST_ERROR = None
        return buses
    except Exception as e:
        LIVE_DATA_LAST_ERROR = str(e)
        return None

@app.route('/health')
def health():
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.utcnow().isoformat(),
        'liveDataConfigured': bool(os.getenv('IBB_TRAFFIC_API_URL', '').strip()),
        'liveDataLastError': LIVE_DATA_LAST_ERROR,
    })

def mock_stops(route_id, stop_count=12):
    import random

    center_lat, center_lng = ROUTE_CENTERS.get(route_id, (41.0082, 28.9784))
    base_bearing = random.uniform(0, 2 * np.pi)
    points = []
    for i in range(stop_count):
        # Basit bir hat eğrisi oluşturup durakları bu çizgi üzerine dizer.
        step = i / max(stop_count - 1, 1)
        lat = center_lat + (step - 0.5) * 0.12 + np.sin(step * np.pi) * 0.01
        lng = center_lng + (step - 0.5) * 0.12 + np.cos(step * np.pi) * 0.01

        # Rota yönünü farklılaştırmak için küçük bir rotasyon uygula.
        d_lat = lat - center_lat
        d_lng = lng - center_lng
        rot_lat = d_lat * np.cos(base_bearing) - d_lng * np.sin(base_bearing)
        rot_lng = d_lat * np.sin(base_bearing) + d_lng * np.cos(base_bearing)

        points.append({
            'id': f'{route_id}_{i+1}',
            'name': f'{route_id} Durak {i+1}',
            'lat': round(center_lat + rot_lat, 6),
            'lng': round(center_lng + rot_lng, 6),
        })
    return points

def mock_incidents(route_id):
    route_id = route_id.upper().strip()
    now = datetime.utcnow()
    center_lat, center_lng = ROUTE_CENTERS.get(route_id, (41.0082, 28.9784))
    all_incidents = [
        {
            'incidentId': f'{route_id}_accident_1',
            'routeId': route_id,
            'type': 'accident',
            'severity': 'high',
            'title': f'{route_id} hattinda kaza bildirimi',
            'description': 'Guzergah uzerinde kaza nedeniyle gecikme bekleniyor.',
            'lat': round(center_lat + 0.012, 6),
            'lng': round(center_lng - 0.009, 6),
            'delayMin': 14,
            'active': True,
            'createdAt': (now - timedelta(minutes=8)).isoformat(),
        },
        {
            'incidentId': f'{route_id}_roadwork_1',
            'routeId': route_id,
            'type': 'roadwork',
            'severity': 'medium',
            'title': f'{route_id} hattinda yol calismasi',
            'description': 'Tek serit gecise dusuldu, sefer suresi uzayabilir.',
            'lat': round(center_lat - 0.008, 6),
            'lng': round(center_lng + 0.01, 6),
            'delayMin': 7,
            'active': True,
            'createdAt': (now - timedelta(minutes=19)).isoformat(),
        },
        {
            'incidentId': f'{route_id}_cleared_1',
            'routeId': route_id,
            'type': 'closure',
            'severity': 'low',
            'title': f'{route_id} hattinda onceki kapanis acildi',
            'description': 'Sorun giderildi, hat normal akisa donuyor.',
            'lat': round(center_lat + 0.005, 6),
            'lng': round(center_lng + 0.006, 6),
            'delayMin': 0,
            'active': False,
            'createdAt': (now - timedelta(minutes=55)).isoformat(),
        },
    ]
    return all_incidents


def apply_recent_user_report(route_id, base_score, now):
    report_key = route_id
    if report_key not in USER_REPORTS:
        return base_score, False, None, 0.0

    last_report = USER_REPORTS[report_key]
    age_min = (now - last_report['timestamp']).total_seconds() / 60.0
    if age_min > 30:
        return base_score, False, age_min, 0.0

    freshness = max(0.0, 1.0 - (age_min / 30.0))
    mixed_score = (last_report['score'] * 0.7) + (base_score * 0.3)
    return mixed_score, True, age_min, freshness


@app.route('/get_stops/<route_id>')
def get_stops(route_id):
    route_id = route_id.upper().strip()
    now = datetime.utcnow()
    center = ROUTE_CENTERS.get(route_id, (41.0082, 28.9784))
    base_score = predict_density(center[0], center[1], 50)
    effective_score, _, _, _ = apply_recent_user_report(route_id, base_score, now)

    # Yoğunluk arttıkça durak ETA'ları uzasın.
    minutes_per_stop = 1.4 + (effective_score * 2.8)
    stops = mock_stops(route_id)
    for i, stop in enumerate(stops):
        stop['etaMin'] = int(round((i + 1) * minutes_per_stop))

    return jsonify({
        'routeId': route_id,
        'stops': stops,
        'count': len(stops),
    }), 200

@app.route('/get_incidents/<route_id>')
def get_incidents(route_id):
    route_id = route_id.upper().strip()
    incidents = mock_incidents(route_id)
    active_incidents = [i for i in incidents if i.get('active', False)]
    return jsonify({
        'routeId': route_id,
        'count': len(incidents),
        'activeCount': len(active_incidents),
        'incidents': incidents,
    }), 200

@app.route('/predict_location')
def predict_location():
    try:
        lat   = float(request.args['lat'])
        lng   = float(request.args['lng'])
        speed = float(request.args.get('speed', 50))
    except (KeyError, ValueError):
        return jsonify({'error': 'lat ve lng zorunlu'}), 400
    score = predict_density(lat, lng, speed)
    return jsonify({
        'lat': lat, 'lng': lng,
        'densityScore': round(score, 3),
        'densityLabel': score_label(score),
        'timestamp': datetime.utcnow().isoformat(),
    })

@app.route('/routes')
def get_routes():
    # ROUTE_CENTERS içindeki tüm hatları otomatik olarak listeye çevirir
    routes_list = []
    
    for route_id in ROUTE_CENTERS.keys():
        # Hat ismine göre otomatik bir 'type' (tür) belirliyoruz
        if route_id.startswith('M') and route_id != 'MARMARAY':
            route_type = 'metro'
        elif route_id == 'MARMARAY':
            route_type = 'marmaray'
        elif route_id.startswith('T') and not route_id.startswith('TF'):
            route_type = 'tramvay'
        elif route_id.startswith('TF'):
            route_type = 'teleferik'
        elif route_id.startswith('F'):
            route_type = 'vapur'
        elif route_id in ['34B', '34BZ']:
            route_type = 'metrobus'
        elif route_id.startswith('E') or route_id.startswith('EXP') or route_id == '500T':
             route_type = 'ekspres'
        else:
            route_type = 'bus' # Geriye kalanlar büyük ihtimalle standart otobüs

        routes_list.append({
            'routeId': route_id,
            'lineName': f'{route_id} Hatti', # Şimdilik sadece adını yazıyoruz (Örn: "M2 Hatti")
            'type': route_type
        })
        
    return jsonify(routes_list)

@app.route('/report_density', methods=['POST'])
def report_density():
    try:
        data = request.get_json()
        route_id = data.get('routeId', '').upper().strip()
        reported_score = float(data.get('densityScore')) # 0.0 ile 1.0 arası bir değer bekliyoruz
        if not route_id:
            return jsonify({'error': 'routeId zorunlu'}), 400
        report_key = route_id
        
        # Bildirimi zaman damgasıyla birlikte kaydet
        USER_REPORTS[report_key] = {
            'score': reported_score,
            'timestamp': datetime.utcnow()
        }
        return jsonify({'status': 'success', 'message': 'Bildirim basariyla kaydedildi.'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 400


@app.route('/get_prediction/<route_id>')
def get_prediction(route_id):
    route_id = route_id.upper().strip()
    center = ROUTE_CENTERS.get(route_id, (41.0082, 28.9784))
    try:
        lat   = float(request.args.get('lat',   center[0]))
        lng   = float(request.args.get('lng',   center[1]))
        speed = float(request.args.get('speed', 50))
    except ValueError:
        return jsonify({'error': 'Gecersiz parametre'}), 400

    try:
        live_buses = fetch_live_buses(route_id)
        buses = live_buses if live_buses else mock_buses(route_id)
        source = 'ibb_live' if live_buses else 'mock'
        base_score    = predict_density(lat, lng, speed)
        current_score = base_score
        now           = datetime.utcnow()
        current_score, report_used, report_age_min, report_freshness = apply_recent_user_report(
            route_id, base_score, now
        )

        bus_coverage = min(len(buses) / 8.0, 1.0)
        report_signal = report_freshness if report_used else 0.25
        confidence_score = max(
            0.35,
            min(0.99, 0.40 + (0.35 * bus_coverage) + (0.25 * report_signal))
        )

        forecast      = [
            {
                'minutesAhead': m,
                'densityScore': round(predict_density(lat, lng, speed,
                                    now + timedelta(minutes=m)), 3),
                'label': score_label(predict_density(lat, lng, speed,
                                    now + timedelta(minutes=m)))
            }
            for m in [30, 60]
        ]
        return jsonify({
            'routeId':      route_id,
            'densityScore': round(current_score, 3),
            'densityLabel': score_label(current_score),
            'confidenceScore': round(confidence_score, 3),
            'confidenceLabel': confidence_label(confidence_score),
            'reportUsed': report_used,
            'reportAgeMin': None if report_age_min is None else round(report_age_min, 1),
            'busCount':     len(buses),
            'busDataSource': source,
            'buses':        buses,
            'forecast':     forecast,
            'timestamp':    now.isoformat(),
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app_port = int(os.getenv('PORT', '5000'))
    app_debug = os.getenv('APP_DEBUG', '1').strip().lower() in ('1', 'true', 'yes')
    app.run(host='0.0.0.0', port=app_port, debug=app_debug)
