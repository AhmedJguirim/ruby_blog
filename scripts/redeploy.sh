#!/usr/bin/env bash
# Rebuild and restart from the code on disk. No git, the database is not touched.
#   scripts/redeploy.sh [--no-cache] [-q]
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BUILD_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --no-cache) BUILD_ARGS=(--no-cache --pull); shift ;;
    -q) QUIET=1; shift ;;
    -h|--help) sed -n '2,3p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

need_cmds docker git flock
require_env
acquire_lock

log "redeploying $(short HEAD) from the working tree"
build_images "${BUILD_ARGS[@]}"
start_stack
if wait_healthy; then
  git diff --quiet HEAD 2>/dev/null && record_good "$(head_commit)"
  log "redeploy done"
else
  show_failure_logs
  die "the stack is not healthy after the redeploy"
fi
