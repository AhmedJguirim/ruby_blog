#!/usr/bin/env bash
# Creates .env from .env.example with random secrets.
#   scripts/init-env.sh --email you@example.com --url https://blog.example.com [--force]
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

usage() { echo "Usage: $0 --email EMAIL --url URL [--port PORT] [--force]"; exit "${1:-0}"; }

EMAIL=""; URL=""; PORT=""; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --email) EMAIL="${2:-}"; shift 2 ;;
    --url)   URL="${2:-}"; shift 2 ;;
    --port)  PORT="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

[[ "$EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]] || { echo "--email must be a valid address" >&2; usage 1; }
[[ "$URL" =~ ^https?://[^/[:space:]]+$ ]] || { echo "--url must look like https://blog.example.com (no trailing path)" >&2; usage 1; }
port_busy() { # true if something already listens on the port (any address)
  if command -v ss >/dev/null; then ss -H -ltn "sport = :$1" 2>/dev/null | grep -q .
  else (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; fi
}
if [ -n "$PORT" ]; then
  [[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || { echo "--port must be 1024-65535" >&2; usage 1; }
  ! port_busy "$PORT" || { echo "Port $PORT is already in use on this machine; choose another with --port." >&2; exit 1; }
else
  PORT=18090
  for _ in $(seq 1 50); do
    ! port_busy "$PORT" && break
    PORT=$((20000 + RANDOM % 30000))
  done
  ! port_busy "$PORT" || { echo "Could not find a free port; give one with --port." >&2; exit 1; }
fi
command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }

if [ -e .env ] && [ "$FORCE" -ne 1 ]; then
  echo ".env already exists. Use --force to replace it (secrets change, sessions are invalidated)." >&2
  exit 1
fi

umask 077
if [ -e .env ]; then
  cp -p .env ".env.bak.$(date +%Y%m%d-%H%M%S)"
fi

# plain http on a non-local address means people reach nginx directly: bind to all interfaces
BIND="127.0.0.1"
if [[ "$URL" == http://* ]] && [[ ! "$URL" =~ ^http://(localhost|127\.0\.0\.1)(:|$) ]]; then BIND="0.0.0.0"; fi

SECRET_KEY_BASE="$(openssl rand -hex 64)"
JWT_SECRET_KEY="$(openssl rand -hex 32)"
ADMIN_PASSWORD="$(openssl rand -hex 12)"

tmp="$(mktemp .env.XXXXXX)"
trap 'rm -f "$tmp"' EXIT
cp .env.example "$tmp"
set_var() { # KEY VALUE
  awk -v k="$1" -v v="$2" 'BEGIN{FS=OFS="="} $1==k{print k "=" v; next} {print}' "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
}
set_var APP_URL "$URL"
set_var WEB_PORT "$PORT"
set_var BIND_ADDR "$BIND"
set_var SECRET_KEY_BASE "$SECRET_KEY_BASE"
set_var JWT_SECRET_KEY "$JWT_SECRET_KEY"
set_var ADMIN_EMAIL "$EMAIL"
set_var ADMIN_PASSWORD "$ADMIN_PASSWORD"
set_var MAIL_FROM "$EMAIL"
chmod 600 "$tmp"
mv "$tmp" .env
trap - EXIT

echo "Wrote .env (mode 600)."
echo "  Site URL:        $URL  (nginx on ${BIND}:${PORT})"
echo "  First user:      $EMAIL"
echo "  First password:  $ADMIN_PASSWORD   <- shown only now, change it after the first login"
