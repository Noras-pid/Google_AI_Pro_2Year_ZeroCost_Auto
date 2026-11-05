#!/usr/bin/env bash
# Daily-use launcher: just start the console.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

PY="${PYTHON:-python3}"

echo "======================================================================"
echo "  Google AI Pro (5 TB) zero-cost 2-year automation console"
echo "  URL: http://127.0.0.1:8765"
echo "======================================================================"

( sleep 2 && command -v xdg-open >/dev/null && xdg-open "http://127.0.0.1:8765" >/dev/null 2>&1 ) &

exec "$PY" app.py
