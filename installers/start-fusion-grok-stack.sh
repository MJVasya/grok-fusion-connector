#!/usr/bin/env bash
# Hidden stack: Fusion MCP bridge + Cloudflare quick tunnel.
# Prints GROK_CONNECTOR_URL = https://<trycloudflare-host>/mcp
set -euo pipefail

LISTEN="${BRIDGE_LISTEN:-127.0.0.1}"
PORT="${BRIDGE_PORT:-18782}"
UPSTREAM="${FUSION_MCP_UPSTREAM:-http://127.0.0.1:27182}"
WAIT_SECS="${TUNNEL_WAIT:-45}"
STATE="${GROK_FUSION_STATE:-$HOME/.grok/fusion-stack}"
mkdir -p "$STATE"
LOG="$STATE/cloudflared.log"
URL_FILE="$STATE/connector.url"
PID_BRIDGE="$STATE/bridge.pid"
PID_CF="$STATE/cloudflared.pid"

resolve_bridge() {
  local SOURCE DIR ROOT c
  SOURCE="${BASH_SOURCE[0]}"
  while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="${DIR}/${SOURCE}"
  done
  SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  for c in \
    "${GROK_FUSION_LIBEXEC:-}/bridge/fusion_mcp_bridge.py" \
    "${ROOT}/bridge/fusion_mcp_bridge.py"
  do
    [[ -n "${c}" && -f "$c" ]] && echo "$c" && return 0
  done
  return 1
}

stop_old() {
  for f in "$PID_BRIDGE" "$PID_CF"; do
    if [[ -f "$f" ]]; then
      kill "$(cat "$f")" 2>/dev/null || true
      rm -f "$f"
    fi
  done
}

extract_url() {
  local host
  host="$(
    grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" 2>/dev/null \
      | tail -n 1 || true
  )"
  [[ -n "$host" ]] && echo "${host}/mcp"
}

BRIDGE="$(resolve_bridge)" || {
  echo "missing fusion_mcp_bridge.py (brew reinstall --HEAD or set GROK_FUSION_LIBEXEC)"
  exit 1
}
command -v cloudflared >/dev/null || {
  echo "install cloudflared: brew install cloudflare/cloudflare/cloudflared"
  exit 1
}
command -v python3 >/dev/null || { echo "python3 required"; exit 1; }

stop_old
: > "$LOG"
rm -f "$URL_FILE"

python3 "$BRIDGE" --listen "$LISTEN" --port "$PORT" --upstream "$UPSTREAM" \
  >/dev/null 2>"$STATE/bridge.log" &
echo $! > "$PID_BRIDGE"
sleep 0.4
if ! kill -0 "$(cat "$PID_BRIDGE")" 2>/dev/null; then
  echo "bridge failed to start"; cat "$STATE/bridge.log"; exit 1
fi

nohup cloudflared tunnel --no-autoupdate --url "http://${LISTEN}:${PORT}" \
  >"$LOG" 2>&1 &
echo $! > "$PID_CF"

echo "Waiting up to ${WAIT_SECS}s for trycloudflare hostname..."
URL=""
for _ in $(seq 1 "$WAIT_SECS"); do
  URL="$(extract_url || true)"
  if [[ -n "$URL" ]]; then
    break
  fi
  sleep 1
done

if [[ -z "$URL" ]]; then
  echo "FAIL: no trycloudflare host in $LOG"
  tail -n 40 "$LOG"
  exit 1
fi

printf '%s\n' "$URL" > "$URL_FILE"
printf 'GROK_CONNECTOR_URL=%s\n' "$URL"
echo "$URL" | pbcopy 2>/dev/null || true
echo
echo "Paste into grok.com/connectors → Custom → MCP URL"
echo "  $URL"
echo
echo "PIDs: bridge=$(cat "$PID_BRIDGE") cloudflared=$(cat "$PID_CF")"
echo "Stop: kill \$(cat $PID_BRIDGE $PID_CF); rm -f $PID_BRIDGE $PID_CF"
echo "Logs: $LOG"
