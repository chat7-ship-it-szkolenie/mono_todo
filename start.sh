#!/usr/bin/env bash
# Start backend (uvicorn) + frontend (vite) for local development
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/services/backend"
FRONTEND_DIR="$ROOT_DIR/services/frontend"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Sanity checks ─────────────────────────────────────────────────────────────

if [[ ! -d "$BACKEND_DIR/.venv" ]]; then
  error "Backend not installed. Run ./install.sh first."
  exit 1
fi

if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
  error "Frontend not installed. Run ./install.sh first."
  exit 1
fi

if [[ ! -f "$BACKEND_DIR/.env" ]]; then
  error ".env missing. Run ./install.sh to generate it."
  exit 1
fi

# ── PID tracking ──────────────────────────────────────────────────────────────

PIDS_FILE="$ROOT_DIR/.dev-pids"
: > "$PIDS_FILE"

cleanup() {
  echo ""
  info "Stopping services..."
  if [[ -f "$PIDS_FILE" ]]; then
    while IFS= read -r pid; do
      kill "$pid" 2>/dev/null && ok "Stopped PID $pid" || true
    done < "$PIDS_FILE"
    rm -f "$PIDS_FILE"
  fi
}
trap cleanup EXIT INT TERM

# ── Backend ───────────────────────────────────────────────────────────────────

info "Starting backend on http://localhost:8000 ..."
(
  cd "$BACKEND_DIR"
  source .venv/bin/activate
  set -a; source .env; set +a
  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload \
    2>&1 | sed 's/^/[backend] /'
) &
BACKEND_PID=$!
echo "$BACKEND_PID" >> "$PIDS_FILE"
ok "Backend PID $BACKEND_PID"

# ── Wait for backend to be ready ──────────────────────────────────────────────

info "Waiting for backend health check..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
    ok "Backend is up"
    break
  fi
  sleep 1
  if [[ $i -eq 30 ]]; then
    warn "Backend did not respond in 30s — check logs above"
  fi
done

# ── Frontend ──────────────────────────────────────────────────────────────────

info "Starting frontend on http://localhost:5173 ..."
(
  cd "$FRONTEND_DIR"
  npm run dev 2>&1 | sed 's/^/[frontend] /'
) &
FRONTEND_PID=$!
echo "$FRONTEND_PID" >> "$PIDS_FILE"
ok "Frontend PID $FRONTEND_PID"

# ── Ready ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  All services running  (Ctrl+C to stop)${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "    Frontend:  http://localhost:5173"
echo "    Backend:   http://localhost:8000"
echo "    API docs:  http://localhost:8000/docs"
echo ""

wait
