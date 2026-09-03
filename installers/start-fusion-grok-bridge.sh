#!/usr/bin/env bash
set -euo pipefail

LISTEN="${BRIDGE_LISTEN:-127.0.0.1}"
PORT="${BRIDGE_PORT:-18782}"
UPSTREAM="${FUSION_MCP_UPSTREAM:-http://127.0.0.1:27182}"

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BRIDGE="${ROOT}/bridge/fusion_mcp_bridge.py"

if [[ ! -f "$BRIDGE" ]]; then
  echo "missing $BRIDGE"
  exit 1
fi

echo "Starting bridge on http://${LISTEN}:${PORT}/mcp"
python3 "$BRIDGE" --listen "$LISTEN" --port "$PORT" --upstream "$UPSTREAM" &
BPID=$!
trap 'kill $BPID 2>/dev/null || true' EXIT
sleep 0.4

echo
echo "Local Grok CLI:"
echo "  grok mcp add --transport http fusion360 http://${LISTEN}:${PORT}/mcp"
echo
echo "grok.com — keep this terminal open:"
echo "  cloudflared tunnel --url http://${LISTEN}:${PORT}"
echo "Use the printed https://….trycloudflare.com/mcp  (no --http-host-header needed)"
echo

if [[ "${START_TUNNEL:-0}" == "1" ]]; then
  exec cloudflared tunnel --url "http://${LISTEN}:${PORT}"
fi

wait $BPID
