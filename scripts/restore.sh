#!/usr/bin/env bash
# Restore the database and the uploads from backups/ (asks first).
#   scripts/restore.sh [-y] [--db FILE] [--uploads FILE]
# Without options the newest backup is used. The current data is backed up first.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

YES=0; DB=""; UP=""
while [ $# -gt 0 ]; do
  case "$1" in
    -y) YES=1; shift ;;
    --db) DB="${2:?--db needs a file}"; shift 2 ;;
    --uploads) UP="${2:?--uploads needs a file}"; shift 2 ;;
    -h|--help) sed -n '2,4p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

need_cmds docker gzip tar flock
require_env
acquire_lock

[ -n "$DB" ] || DB="$(ls -1t "$BACKUP_DIR"/db-*.sqlite3.gz 2>/dev/null | head -n1 || true)"
[ -n "$DB" ] && [ -f "$DB" ] || die "no database backup found in backups/"
if [ -z "$UP" ]; then
  UP="${DB/\/db-/\/uploads-}"; UP="${UP%.sqlite3.gz}.tar.gz"
  [ -f "$UP" ] || UP="$(ls -1t "$BACKUP_DIR"/uploads-*.tar.gz 2>/dev/null | head -n1 || true)"
fi
gzip -t "$DB" || die "$DB is corrupt"
[ -z "$UP" ] || tar -tzf "$UP" >/dev/null || die "$UP is corrupt"

echo "This REPLACES the live data:"
echo "  database: $DB"
echo "  uploads:  ${UP:-(none, uploads stay as they are)}"
if [ "$YES" != 1 ]; then
  read -r -p 'Type "restore" to continue: ' answer
  [ "$answer" = restore ] || die "cancelled"
fi

if web_running; then "$ROOT/scripts/backup.sh" $(child_quiet) || die "the safety backup failed; not restoring"; fi

log "stopping the stack (volumes are kept)"
dc stop nginx web >> "$LOG_FILE" 2>&1 || true

log "restoring the database"
gzip -dc "$DB" | dc run --rm --no-deps -T --entrypoint sh web -c \
  'rm -f "$DATABASE_PATH" "$DATABASE_PATH-wal" "$DATABASE_PATH-shm" && cat > "$DATABASE_PATH"'
if [ -n "$UP" ]; then
  log "restoring the uploads"
  gzip -dc "$UP" | dc run --rm --no-deps -T --entrypoint sh web -c \
    'find /rails/storage -mindepth 1 -delete && tar -xzf - -C /rails/storage'
fi

start_stack
if wait_healthy; then log "restore done"; else show_failure_logs; die "the stack is not healthy after the restore"; fi
