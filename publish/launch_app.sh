#!/bin/bash
# Detach Django runserver from the GitHub Actions runner's process tree.
# Combines: nohup (ignore SIGHUP) + double-fork + setsid (new session) + stdio
# redirection. This is the only combination that survives the runner's
# job-cleanup phase on macOS.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$REPO_ROOT/server.log"
PID_FILE="$REPO_ROOT/server.pid"

cd "$REPO_ROOT/djangotutorial"

# Run any pending DB migrations so /polls/ doesn't 500.
"$REPO_ROOT/.venv/bin/python" manage.py migrate --noinput >>"$LOG_FILE" 2>&1 || true

"$REPO_ROOT/.venv/bin/python" <<PYEOF >/dev/null 2>&1 &
import os, sys, signal, subprocess
# First fork
if os.fork() != 0: os._exit(0)
# New session — detach from controlling tty and parent process group
os.setsid()
# Ignore SIGHUP so the runner's cleanup can't kill us
signal.signal(signal.SIGHUP, signal.SIG_IGN)
# Second fork — guarantees we are not a session leader
if os.fork() != 0: os._exit(0)
# Redirect stdio
log = open("$LOG_FILE", "ab", buffering=0)
os.dup2(log.fileno(), 1)
os.dup2(log.fileno(), 2)
devnull = open("/dev/null", "rb")
os.dup2(devnull.fileno(), 0)
# Launch the server
p = subprocess.Popen(
    ["$REPO_ROOT/.venv/bin/python", "manage.py", "runserver", "0.0.0.0:8000", "--noreload"],
    start_new_session=False,  # already in new session
)
with open("$PID_FILE", "w") as f: f.write(str(p.pid))
p.wait()
PYEOF

disown -a 2>/dev/null || true
sleep 1
echo "Launched (pid file: $PID_FILE)"
