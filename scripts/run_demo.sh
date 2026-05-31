#!/usr/bin/env bash
# Demo / presentation: Flutter app → Render HTTPS API
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_URL="${API_BASE_URL:-https://stanbul-traff-c-forecast.onrender.com}"

echo "Checking backend health at $API_URL/health ..."
if command -v curl >/dev/null 2>&1; then
  curl -sf "$API_URL/health" | head -c 200 || echo "(health check failed — deploy may be sleeping; open app anyway)"
  echo ""
fi

echo "Starting Flutter with API_BASE_URL=$API_URL"
flutter run --dart-define=API_BASE_URL="$API_URL"
