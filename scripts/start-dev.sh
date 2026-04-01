#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
MAVEN_REPO_DIR="/tmp/approval-system-m2"
BACKEND_LOG="$RUN_DIR/backend.log"
FRONTEND_LOG="$RUN_DIR/frontend.log"
BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"
BACKEND_PORT_FILE="$RUN_DIR/backend.port"
FRONTEND_PORT_FILE="$RUN_DIR/frontend.port"
BACKEND_DEFAULT_PORT=8080
FRONTEND_DEFAULT_PORT=5173

mkdir -p "$RUN_DIR"

read_pid() {
  local pid_file="$1"
  [[ -f "$pid_file" ]] || return 1

  local pid
  pid="$(tr -d '[:space:]' <"$pid_file")"
  [[ -n "$pid" ]] || return 1
  printf '%s\n' "$pid"
}

is_pid_running() {
  local pid="$1"
  kill -0 "$pid" >/dev/null 2>&1
}

is_port_in_use() {
  local port="$1"
  (echo >"/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1
}

find_available_port() {
  local port="$1"
  while is_port_in_use "$port"; do
    port=$((port + 1))
  done
  printf '%s\n' "$port"
}

wait_for_port() {
  local port="$1"
  local name="$2"
  local attempts="${3:-60}"
  local log_file="${4:-}"
  local extend_keyword="${5:-}"

  for ((i = 1; i <= attempts; i++)); do
    if is_port_in_use "$port"; then
      return 0
    fi

    if [[ -n "$log_file" && -n "$extend_keyword" ]] && latest_log_contains "$log_file" "$extend_keyword"; then
      attempts=$((attempts + 1))
    fi
    sleep 1
  done

  echo "$name failed to open port $port"
  return 1
}

latest_log_contains() {
  local log_file="$1"
  local keyword="$2"
  local last_line=""

  [[ -f "$log_file" ]] || return 1

  last_line="$(tail -n 1 "$log_file" 2>/dev/null || true)"
  [[ "$last_line" == *"$keyword"* ]]
}

wait_for_http() {
  local url="$1"
  local name="$2"
  local attempts="${3:-60}"

  for ((i = 1; i <= attempts; i++)); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "$name failed health check: $url"
  return 1
}

capture_service_pid() {
  local name="$1"
  local pattern="$2"
  local pid_file="$3"
  local pid=""

  pid="$(pgrep -n -f "$pattern" || true)"
  if [[ -z "$pid" ]]; then
    echo "Failed to capture $name PID"
    return 1
  fi

  echo "$pid" >"$pid_file"
}

cleanup_pid_file() {
  local pid_file="$1"
  local port_file="$2"
  rm -f "$pid_file" "$port_file"
}

terminate_pid() {
  local pid="$1"
  local name="$2"

  if ! is_pid_running "$pid"; then
    return 0
  fi

  kill "$pid" >/dev/null 2>&1 || true
  for ((i = 1; i <= 10; i++)); do
    if ! is_pid_running "$pid"; then
      return 0
    fi
    sleep 1
  done

  kill -9 "$pid" >/dev/null 2>&1 || true
  for ((i = 1; i <= 5; i++)); do
    if ! is_pid_running "$pid"; then
      return 0
    fi
    sleep 1
  done

  echo "Failed to stop $name process $pid"
  return 1
}

stop_tracked_process() {
  local name="$1"
  local pid_file="$2"
  local port_file="$3"

  local pid=""
  if pid="$(read_pid "$pid_file" 2>/dev/null)"; then
    if is_pid_running "$pid"; then
      echo "Stopping existing $name process (PID $pid) ..."
      terminate_pid "$pid" "$name"
    fi
  fi

  cleanup_pid_file "$pid_file" "$port_file"
}

stop_matching_processes() {
  local name="$1"
  local pattern="$2"
  local pids

  pids="$(pgrep -f "$pattern" || true)"
  [[ -n "$pids" ]] || return 0

  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    echo "Stopping residual $name process (PID $pid) ..."
    terminate_pid "$pid" "$name"
  done <<<"$pids"
}

cleanup_existing_processes() {
  stop_tracked_process "backend" "$BACKEND_PID_FILE" "$BACKEND_PORT_FILE"
  stop_tracked_process "frontend" "$FRONTEND_PID_FILE" "$FRONTEND_PORT_FILE"
  stop_matching_processes "backend" "$ROOT_DIR/.+spring-boot:run"
  stop_matching_processes "frontend" "$ROOT_DIR/frontend.+vite"
}

start_backend() {
  local backend_port
  backend_port="$(find_available_port "$BACKEND_DEFAULT_PORT")"
  echo "Starting backend on http://localhost:$backend_port ..."
  mkdir -p "$MAVEN_REPO_DIR"
  local command
  command="cd \"$ROOT_DIR\" && exec ./mvnw -Dmaven.repo.local=$MAVEN_REPO_DIR -Dspring-boot.run.useTestClasspath=true -Dspring-boot.run.arguments='--server.port=$backend_port --spring.datasource.url=jdbc:h2:mem:approval_system_dev;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE --spring.datasource.driver-class-name=org.h2.Driver --spring.datasource.username=sa --spring.datasource.password= --spring.jpa.hibernate.ddl-auto=update --spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect' spring-boot:run"
  : >"$BACKEND_LOG"
  setsid /usr/bin/env bash -lc "$command" >"$BACKEND_LOG" 2>&1 < /dev/null &
  echo "$backend_port" >"$BACKEND_PORT_FILE"

  wait_for_port "$backend_port" "Backend" 90 "$BACKEND_LOG" "Downloading" || {
    echo "Backend log: $BACKEND_LOG"
    return 1
  }
  wait_for_http "http://127.0.0.1:$backend_port/api/auth/bootstrap-status" "Backend" 30 || {
    echo "Backend log: $BACKEND_LOG"
    return 1
  }
  capture_service_pid \
    "backend" \
    "com.flowablecollab.approval_system.ApprovalSystemApplication --server.port=$backend_port" \
    "$BACKEND_PID_FILE"
}

start_frontend() {
  local backend_port frontend_port
  backend_port="$(cat "$BACKEND_PORT_FILE")"
  frontend_port="$(find_available_port "$FRONTEND_DEFAULT_PORT")"
  echo "Starting frontend on http://localhost:$frontend_port ..."
  : >"$FRONTEND_LOG"
  setsid /usr/bin/env bash -lc "source ~/.nvm/nvm.sh >/dev/null 2>&1 && nvm use 24.7.0 >/dev/null 2>&1 || true; cd \"$ROOT_DIR\" && export VITE_API_TARGET=http://127.0.0.1:$backend_port && exec npm -C frontend run dev -- --host 0.0.0.0 --port $frontend_port --strictPort" \
    >"$FRONTEND_LOG" 2>&1 < /dev/null &
  echo "$frontend_port" >"$FRONTEND_PORT_FILE"

  wait_for_port "$frontend_port" "Frontend" 30 || {
    echo "Frontend log: $FRONTEND_LOG"
    return 1
  }
  wait_for_http "http://127.0.0.1:$frontend_port/" "Frontend" 15 || {
    echo "Frontend log: $FRONTEND_LOG"
    return 1
  }
  wait_for_http "http://127.0.0.1:$frontend_port/api/auth/bootstrap-status" "Frontend proxy" 15 || {
    echo "Expected backend: http://127.0.0.1:$backend_port"
    echo "Frontend log: $FRONTEND_LOG"
    return 1
  }
  capture_service_pid \
    "frontend" \
    "$ROOT_DIR/frontend/node_modules/.bin/vite --host 0.0.0.0 --port $frontend_port --strictPort" \
    "$FRONTEND_PID_FILE"
}

cleanup_existing_processes
start_backend
start_frontend

BACKEND_PORT="$(cat "$BACKEND_PORT_FILE")"
FRONTEND_PORT="$(cat "$FRONTEND_PORT_FILE")"

echo
echo "Frontend: http://localhost:$FRONTEND_PORT"
echo "Backend:  http://localhost:$BACKEND_PORT"
echo "Logs (实时持续记录):"
echo "  $BACKEND_LOG"
echo "  $FRONTEND_LOG"
echo
echo "查看实时日志:"
echo "  tail -f $BACKEND_LOG"
echo "  tail -f $FRONTEND_LOG"
