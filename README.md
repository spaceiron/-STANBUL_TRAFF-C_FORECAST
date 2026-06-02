# TrafikPuls — Istanbul Traffic Forecast

**Student:** Uzay Demir — **210218027**  
Mobile crowd-density decision support for Istanbul public transport.

**Stack:** Flutter · Firebase (Auth, Firestore, FCM) · Flask · scikit-learn (Random Forest) · Render

## Project structure

```
lib/           Flutter app (screens, services, models)
backend/       Flask API + ML model + route geometry
docs/          UML / architecture diagrams (SVG)
scripts/       run_demo.sh, run_backend_local.sh
```

## Run the app

```bash
./scripts/run_demo.sh
# or: flutter run
```

Default API: Render HTTPS (`lib/config/app_config.dart`).

Local backend:

```bash
./scripts/run_backend_local.sh
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

## Backend

- `GET /get_prediction/<routeId>` — density + forecast
- `GET /get_stops/<routeId>` — route polyline stops
- `GET /get_incidents/<routeId>` — active incidents
- `POST /report_density` — user feedback to model
- `GET /admin/model_metrics` — admin (requires `X-User-Email` header)

Deploy: push to GitHub → Render auto-deploy (`render.yaml`).

## Admin

Only `demor.uzay@gmail.com` (see `lib/config/admin_config.dart`).
