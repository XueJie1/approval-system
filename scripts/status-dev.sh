#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"
BACKEND_PORT_FILE="$RUN_DIR/backend.port"
FRONTEND_PORT_FILE="$RUN_DIR/frontend.port"
BACKEND_LOG="$RUN_DIR/backend.log"
FRONTEND_LOG="$RUN_DIR/frontend.log"

backend_pattern() {
  local port="$1"
  printf 'com.flowablecollab.approval_system.ApprovalSystemApplication --server.port=%s' "$port"
}

frontend_pattern() {
  local port="$1"
  printf '%s/frontend/node_modules/.bin/vite --host 0.0.0.0 --port %s --strictPort' "$ROOT_DIR" "$port"
}

read_file_value() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  tr -d '[:space:]' <"$file"
}

resolve_pid() {
  local pid_file="$1"
  local port_file="$2"
  local pattern_builder="$3"
  local pid=""
  local port=""

  pid="$(read_file_value "$pid_file" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    printf '%s\n' "$pid"
    return 0
  fi

  port="$(read_file_value "$port_file" 2>/dev/null || true)"
  [[ -n "$port" ]] || return 1

  pid="$(pgrep -n -f "$($pattern_builder "$port")" || true)"
  [[ -n "$pid" ]] || return 1

  echo "$pid" >"$pid_file"
  printf '%s\n' "$pid"
}

print_status() {
  local name="$1"
  local pid_file="$2"
  local port_file="$3"
  local log_file="$4"
  local pattern_builder="$5"

  local pid=""
  local port=""
  pid="$(resolve_pid "$pid_file" "$port_file" "$pattern_builder" 2>/dev/null || true)"
  port="$(read_file_value "$port_file" 2>/dev/null || true)"

  if [[ -z "$pid" ]]; then
    echo "$name: stopped"
    return
  fi

  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    if [[ -n "$port" ]]; then
      echo "$name: running (PID $pid, port $port)"
    else
      echo "$name: running (PID $pid)"
    fi
    echo "  log: $log_file"
  else
    echo "$name: stopped (stale PID file)"
  fi
}

print_status "frontend" "$FRONTEND_PID_FILE" "$FRONTEND_PORT_FILE" "$FRONTEND_LOG" frontend_pattern
print_status "backend" "$BACKEND_PID_FILE" "$BACKEND_PORT_FILE" "$BACKEND_LOG" backend_pattern
