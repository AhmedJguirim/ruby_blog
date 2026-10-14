#!/usr/bin/env bash
# Go back to the previous healthy commit (or to COMMIT) and rebuild.
#   scripts/rollback.sh [-y] [COMMIT]
# The commit you leave is put on hold, so scripts/deploy.sh will not redeploy it.
# Database migrations are not undone; use scripts/restore.sh for that.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

YES=0; TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    -y) YES=1; shift ;;
    -q) QUIET=1; shift ;;
    -h|--help) sed -n '2,5p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) TARGET="$1"; shift ;;
  esac
done

need_cmds docker git flock
require_env
acquire_lock
require_clean_tree

CURRENT="$(head_commit)"
if [ -z "$TARGET" ]; then
  TARGET="$(awk '{print $1}' "$HISTORY_FILE" 2>/dev/null | tac | grep -v "^$CURRENT$" | head -n1 || true)"
  [ -n "$TARGET" ] || die "no earlier healthy deploy recorded; give a commit: scripts/rollback.sh <commit>"
fi
TARGET="$(git rev-parse --verify "$TARGET^{commit}" 2>/dev/null)" || die "unknown commit"
[ "$TARGET" != "$CURRENT" ] || die "already at $(short "$TARGET")"

echo "Rollback: $(git log -1 --format='%h %s' "$CURRENT")  ->  $(git log -1 --format='%h %s' "$TARGET")"
if [ "$YES" != 1 ]; then
  read -r -p 'Type "rollback" to continue: ' answer
  [ "$answer" = rollback ] || die "cancelled"
fi

"$ROOT/scripts/backup.sh" $(child_quiet) || die "the backup failed; not rolling back"
git reset --hard --quiet "$TARGET"
echo "$CURRENT" > "$HOLD_FILE"
build_images
start_stack
if wait_healthy; then
  record_good "$TARGET"
  log "rolled back to $(short "$TARGET"); $(short "$CURRENT") is on hold"
else
  show_failure_logs
  die "the stack is not healthy after the rollback"
fi
