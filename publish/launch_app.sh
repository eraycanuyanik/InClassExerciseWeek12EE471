#!/bin/bash
# Launch Django runserver in a detached `screen` session.
# `screen -dmS` creates a fully-detached PTY session that survives the
# GitHub Actions runner's job-cleanup phase on macOS.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$REPO_ROOT/server.log"

cd "$REPO_ROOT/djangotutorial"

# Run any pending DB migrations so /polls/ doesn't 500.
"$REPO_ROOT/.venv/bin/python" manage.py migrate --noinput >>"$LOG_FILE" 2>&1 || true

# Kill any existing screen session named django-app.
screen -S django-app -X quit 2>/dev/null || true
sleep 1

# Start fresh detached session.
# macOS ships an ancient `screen` (4.00.03) that has no -Logfile flag, so
# we redirect via shell instead.
screen -dmS django-app bash -c \
    "exec '$REPO_ROOT/.venv/bin/python' manage.py runserver 0.0.0.0:8000 --noreload >>'$LOG_FILE' 2>&1"

echo "Launched in screen session 'django-app'"
screen -ls | grep django-app || true
