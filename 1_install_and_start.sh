#!/usr/bin/env bash
# First-run launcher: install deps + start console.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

say() { printf '\n======================================================================\n%s\n======================================================================\n' "$*"; }

PY="${PYTHON:-python3}"
if ! command -v "$PY" >/dev/null 2>&1; then
    echo "python3 не найден. Установи python >= 3.10 и повтори."
    exit 1
fi

if ! command -v google-chrome-stable >/dev/null 2>&1 \
   && ! command -v google-chrome >/dev/null 2>&1 \
   && ! command -v chromium >/dev/null 2>&1 \
   && ! command -v chromium-browser >/dev/null 2>&1 \
   && [ ! -x /opt/google/chrome/chrome ]; then
    echo "⚠️  Google Chrome / Chromium не найден."
    echo "    Поставь пакет google-chrome-stable / chromium или задай CHROME_PATH=/полный/путь."
fi

say "Ставлю Python-зависимости (fastapi, uvicorn, playwright, pydantic)..."
"$PY" -m pip install --user -r requirements.txt

say "Проверяю Playwright chromium (нужен для headless-режимов)..."
"$PY" -m playwright install chromium || true

say "Поднимаю Web-консоль на http://127.0.0.1:8765 ..."
( sleep 2 && command -v xdg-open >/dev/null && xdg-open "http://127.0.0.1:8765" >/dev/null 2>&1 ) &

exec "$PY" app.py
