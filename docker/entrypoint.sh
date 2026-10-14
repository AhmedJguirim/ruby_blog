#!/bin/sh
# Prepares the database, then starts the given command.
set -eu
cd /rails

case "$*" in
  *puma*)
    mkdir -p tmp/pids tmp/cache storage "$(dirname "$DATABASE_PATH")"

    # SQLite lives in a volume; make sure it is writable before going on.
    i=0
    until touch "$(dirname "$DATABASE_PATH")/.write-test" 2>/dev/null; do
      i=$((i + 1))
      [ "$i" -ge 30 ] && { echo "database directory is not writable" >&2; exit 1; }
      sleep 1
    done
    rm -f "$(dirname "$DATABASE_PATH")/.write-test"

    echo "== db:prepare"
    bundle exec rails db:prepare

    # only when ADMIN_EMAIL/ADMIN_PASSWORD are set; never any demo data
    bundle exec rails app:create_first_user
    ;;
esac

exec "$@"
