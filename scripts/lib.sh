#!/usr/bin/env bash
# Shared helpers for the deploy scripts. Source it, do not run it.
# Rules: never `docker compose down -v` (it would delete the database and the uploads).

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
STATE_DIR="$ROOT/.deploy"
BACKUP_DIR="$ROOT/backups"
HOLD_FILE="$STATE_DIR/hold"          # commit that failed its health check
HISTORY_FILE="$STATE_DIR/history"    # "<sha> <date>" per healthy deploy, oldest first
LOG_FILE="$STATE_DIR/deploy.log"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-240}"
QUIET="${QUIET:-0}"

umask 077
mkdir -p "$STATE_DIR"

log()  { local line; line="[$(date '+%F %T')] $*"; echo "$line" >> "$LOG_FILE"; [ "$QUIET" = 1 ] || echo "$line"; }
warn() { log "WARNING: $*"; [ "$QUIET" != 1 ] || echo "WARNING: $*" >&2; }
die()  { log "ERROR: $*"; echo "ERROR: $*" >&2; exit 1; }
trap 'echo "ERROR: command failed at ${BASH_SOURCE[1]:-?}:${BASH_LINENO[0]}" >&2' ERR

dc() { docker compose "$@"; }

need_cmds() {
  local c
  for c in "$@"; do command -v "$c" >/dev/null || die "$c is not installed"; done
  docker compose version >/dev/null 2>&1 || die "the docker compose plugin is not installed"
  docker info >/dev/null 2>&1 || die "cannot talk to the Docker daemon (is it running, are you in the docker group?)"
}

require_env() { [ -f "$ROOT/.env" ] || die ".env is missing. Run scripts/init-env.sh first."; }

# One deploy/backup/restore at a time. Child scripts started by a script that
# already holds the lock inherit it (DEPLOY_LOCK_HELD).
acquire_lock() {
  [ "${DEPLOY_LOCK_HELD:-0}" = 1 ] && return 0
  exec 9>"$STATE_DIR/lock"
  flock -n 9 || die "another deploy, backup or restore is running"
  export DEPLOY_LOCK_HELD=1
}

child_quiet() { if [ "$QUIET" = 1 ]; then echo -q; fi; }

head_commit() { git rev-parse HEAD; }
short() { git rev-parse --short "$1"; }

require_clean_tree() {
  [ -z "$(git status --porcelain --untracked-files=no)" ] || die "the working tree has local changes; commit or discard them first"
}

web_running() { [ -n "$(dc ps -q --status running web 2>/dev/null)" ]; }

# running | healthy | unhealthy | starting | exited ... for one service
service_state() {
  local id
  id="$(dc ps -aq "$1" 2>/dev/null | head -n1)"
  [ -n "$id" ] || { echo missing; return; }
  docker inspect -f '{{if .State.Restarting}}restarting{{else if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$id"
}

# Through nginx, like a browser would (the header makes force_ssl happy).
smoke_test() {
  local path
  for path in /up /users/sign_in; do
    dc exec -T nginx wget -q -O /dev/null --header 'X-Forwarded-Proto: https' "http://127.0.0.1:8080$path" >/dev/null 2>&1 || return 1
  done
}

wait_healthy() {
  local deadline=$((SECONDS + HEALTH_TIMEOUT)) web nginx
  log "waiting for the stack to become healthy (up to ${HEALTH_TIMEOUT}s)"
  while [ "$SECONDS" -lt "$deadline" ]; do
    web="$(service_state web)"; nginx="$(service_state nginx)"
    case "$web:$nginx" in
      healthy:healthy)
        smoke_test && { log "healthy: web, nginx and the pages answer"; return 0; } ;;
    esac
    case "$web" in unhealthy|exited|dead|restarting|missing) log "web is $web"; return 1 ;; esac
    sleep 3
  done
  log "timed out: web=$web nginx=$nginx"
  return 1
}

show_failure_logs() { dc logs --no-color --tail 40 web nginx 2>&1 | sed 's/^/    /' >&2 || true; }

build_images() { # [extra build args]
  log "building images"
  if [ "$QUIET" = 1 ]; then dc build "$@" >> "$LOG_FILE" 2>&1 || { tail -n 30 "$LOG_FILE" >&2; return 1; }
  else dc build "$@" 2>&1 | tee -a "$LOG_FILE"; fi
}

start_stack() {
  log "starting containers"
  dc up -d --remove-orphans >> "$LOG_FILE" 2>&1
}

record_good() { # sha
  [ "$(tail -n1 "$HISTORY_FILE" 2>/dev/null | cut -d' ' -f1)" = "$1" ] || echo "$1 $(date '+%F %T')" >> "$HISTORY_FILE"
}
