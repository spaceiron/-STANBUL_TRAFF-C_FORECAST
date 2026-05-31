#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../backend"
export APP_DEBUG=1
export PORT=5000
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi
echo "Local API: http://127.0.0.1:5000/health"
python3 app.py
