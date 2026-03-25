#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"
BACKEND_PORT_FILE="$RUN_DIR/backend.port"
FRONTEND_PORT_FILE="$RUN_DIR/frontend.port"

backend_pattern() {
  local port="$1"
  printf 'com.flowablecollab.approval_system.ApprovalSystemApplication --server.port=%s' "$port"
}

frontend_pattern() {
  local port="$1"
  printf '%s/frontend/node_modules/.bin/vite --host 0.0.0.0 --port %s --strictPort' "$ROOT_DIR" "$port"
}

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

  local pid=""
  if pid="$(read_pid "$pid_file" 2>/dev/null)"; then
    if is_pid_running "$pid"; then
      terminate_pid "$pid" "$name"
      echo "Stopped $name (PID $pid)"
    else
      echo "$name had a stale PID file"
    fi
  else
    echo "$name PID file not found"
  fi

  rm -f "$pid_file"
}

stop_matching_process() {
  local name="$1"
  local pattern="$2"
  local pid

  pid="$(pgrep -n -f "$pattern" || true)"
  [[ -n "$pid" ]] || return 0

  terminate_pid "$pid" "$name"
  echo "Stopped residual $name process (PID $pid)"
}

stop_from_port() {
  local name="$1"
  local port_file="$2"
  local pattern_builder="$3"
  local port=""

  port="$(tr -d '[:space:]' <"$port_file" 2>/dev/null || true)"
  [[ -n "$port" ]] || return 0
  stop_matching_process "$name" "$($pattern_builder "$port")"
}

stop_from_port "frontend" "$FRONTEND_PORT_FILE" frontend_pattern || true
stop_from_port "backend" "$BACKEND_PORT_FILE" backend_pattern || true
stop_tracked_process "frontend" "$FRONTEND_PID_FILE"
stop_tracked_process "backend" "$BACKEND_PID_FILE"
stop_matching_process "frontend" "$ROOT_DIR/frontend.+vite" || true
stop_matching_process "backend" "com.flowablecollab.approval_system.ApprovalSystemApplication" || true
rm -f "$FRONTEND_PORT_FILE" "$BACKEND_PORT_FILE"
