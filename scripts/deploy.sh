#!/usr/bin/env bash
# Update the server to the latest commit of a branch.
#   scripts/deploy.sh [--branch NAME] [--force] [-q]
# fetch -> database backup -> fast-forward -> build -> up -> health check.
# If the new version is not healthy the previous commit is restored and the bad
# commit is put on hold, so it is not retried until it changes (or --force).
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --branch) BRANCH="${2:?--branch needs a name}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -q) QUIET=1; shift ;;
    -h|--help) sed -n '2,6p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

need_cmds docker git flock
require_env
acquire_lock
require_clean_tree

log "fetching origin/$BRANCH"
git fetch --quiet origin "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH" || die "git fetch failed"
NEW="$(git rev-parse "origin/$BRANCH")"

if [ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ]; then
  git checkout --quiet "$BRANCH" 2>/dev/null || git checkout --quiet -b "$BRANCH" "origin/$BRANCH"
fi
PREV="$(head_commit)"

if [ -f "$HOLD_FILE" ] && [ "$(cat "$HOLD_FILE")" = "$NEW" ] && [ "$FORCE" != 1 ]; then
  die "commit $(short "$NEW") failed its health check earlier and is on hold. Push a fix, or use --force to retry it."
fi
if [ "$PREV" = "$NEW" ] && [ "$FORCE" != 1 ] && [ "$(service_state web)" = healthy ] && [ "$(service_state nginx)" = healthy ]; then
  log "already up to date at $(short "$NEW") and healthy"
  exit 0
fi

"$ROOT/scripts/backup.sh" $(child_quiet) || die "the backup failed; not deploying"

log "deploying $(short "$PREV") -> $(short "$NEW") on $BRANCH"
git merge --ff-only --quiet "origin/$BRANCH" || die "cannot fast-forward (does the server have local commits?)"

rollback() {
  warn "deploy of $(short "$NEW") failed"
  show_failure_logs
  echo "$NEW" > "$HOLD_FILE"
  if [ "$PREV" = "$NEW" ]; then die "nothing to roll back to (same commit); fix the problem and run again"; fi
  log "rolling back to $(short "$PREV")"
  git reset --hard --quiet "$PREV"
  if build_images && start_stack && wait_healthy; then
    die "rolled back to $(short "$PREV"); $(short "$NEW") is on hold. Database migrations of the failed version are NOT undone; see scripts/restore.sh."
  fi
  echo "ERROR: the rollback is not healthy either. Check: docker compose logs web" >&2
  exit 2
}

if build_images && start_stack && wait_healthy; then
  rm -f "$HOLD_FILE"
  record_good "$NEW"
  docker image prune -f >/dev/null 2>&1 || true
  log "deployed $(short "$NEW")"
else
  rollback
fi
