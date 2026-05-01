# istanbul_traffic_forecast

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend Live IBB Data (Step 1)

Backend now supports trying a real live feed before falling back to mock buses.

Set these environment variables before running `backend/app.py`:

- `IBB_TRAFFIC_API_URL` (required for live mode)
- `IBB_API_KEY` (optional, if endpoint needs auth)
- `IBB_API_KEY_HEADER` (optional, default: `apikey`)
- `IBB_ROUTE_PARAM` (optional, default: `routeId`)
- `IBB_TIMEOUT_SEC` (optional, default: `4`)

If live feed fails or schema does not match, API automatically uses mock data and keeps returning predictions.

Check `/health` response:

- `liveDataConfigured`: whether live endpoint is set
- `liveDataLastError`: latest live-fetch error (if any)

## Cloud Deploy + HTTPS (Step 2)

This repo is now deployment-ready for Render:

- `backend/requirements.txt`
- `backend/Procfile`
- `render.yaml`

### Deploy backend

1. Push repository to GitHub.
2. Create a new Render Blueprint service from this repo.
3. Render will build `backend` and run `gunicorn app:app`.
4. Use Render URL (HTTPS), for example:
   `https://istanbul-traffic-forecast-api.onrender.com`

### Point Flutter to cloud API

Run app with API URL:

`flutter run --dart-define=API_BASE_URL=https://your-backend-url.onrender.com`

Without `--dart-define`, app keeps using local:
`http://10.0.2.2:5000`
