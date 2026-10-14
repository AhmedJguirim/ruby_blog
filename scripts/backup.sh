#!/usr/bin/env bash
# Backs up the SQLite database and the uploads of the running stack into backups/.
#   scripts/backup.sh [-q] [--keep N]      (default: keep the last 10 of each)
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

KEEP=10
while [ $# -gt 0 ]; do
  case "$1" in
    -q) QUIET=1; shift ;;
    --keep) KEEP="${2:?--keep needs a number}"; shift 2 ;;
    -h|--help) sed -n '2,3p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done
[[ "$KEEP" =~ ^[1-9][0-9]*$ ]] || die "--keep must be a positive number"

need_cmds docker gzip tar
require_env
acquire_lock

if ! web_running; then
  log "the web container is not running: nothing to back up"
  exit 0
fi

mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
DB_FILE="$BACKUP_DIR/db-$TS.sqlite3.gz"
UP_FILE="$BACKUP_DIR/uploads-$TS.tar.gz"
trap 'rm -f "$DB_FILE.part" "$UP_FILE.part"' EXIT

log "dumping the database"
# VACUUM INTO writes a consistent copy even while the app is writing
dc exec -T web bundle exec ruby -rsqlite3 -e '
  dst = "/tmp/backup-#{$$}.sqlite3"
  SQLite3::Database.new(ENV.fetch("DATABASE_PATH")).execute("VACUUM INTO \x27#{dst}\x27")
  STDOUT.binmode
  STDOUT.write(File.binread(dst))
  File.delete(dst)
' | gzip -9 > "$DB_FILE.part"
[ "$(gzip -dc "$DB_FILE.part" | head -c 15)" = "SQLite format 3" ] || die "the database dump is not a valid SQLite file"
mv "$DB_FILE.part" "$DB_FILE"

log "archiving the uploads"
dc exec -T web tar -C /rails/storage -czf - . > "$UP_FILE.part"
tar -tzf "$UP_FILE.part" >/dev/null || die "the uploads archive is not valid"
mv "$UP_FILE.part" "$UP_FILE"
chmod 600 "$DB_FILE" "$UP_FILE"

for pattern in 'db-*.sqlite3.gz' 'uploads-*.tar.gz'; do
  ls -1t "$BACKUP_DIR"/$pattern 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f --
done
log "backup done: $(basename "$DB_FILE") ($(du -h "$DB_FILE" | cut -f1)), $(basename "$UP_FILE") ($(du -h "$UP_FILE" | cut -f1)); keeping the last $KEEP"
