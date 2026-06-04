#!/bin/bash
# Detach Django runserver from the GitHub Actions runner's process tree.
# Without this, the runner kills all child processes when the step ends.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$REPO_ROOT/server.log"
PID_FILE="$REPO_ROOT/server.pid"

cd "$REPO_ROOT/djangotutorial"

# Double-fork via Python so the server becomes a session leader, fully detached.
"$REPO_ROOT/.venv/bin/python" -c "
import os, sys, subprocess
# First fork
if os.fork() != 0: sys.exit(0)
# New session — detach from controlling tty and parent process group
os.setsid()
# Second fork — guarantees we are not a session leader, can't reacquire tty
if os.fork() != 0: sys.exit(0)
# Redirect stdio
log = open('$LOG_FILE', 'ab', buffering=0)
os.dup2(log.fileno(), 1)
os.dup2(log.fileno(), 2)
devnull = open('/dev/null', 'rb')
os.dup2(devnull.fileno(), 0)
# Exec the server
p = subprocess.Popen(['$REPO_ROOT/.venv/bin/python', 'manage.py', 'runserver', '0.0.0.0:8000', '--noreload'])
with open('$PID_FILE', 'w') as f: f.write(str(p.pid))
"

echo "Launched, PID file: $PID_FILE"
