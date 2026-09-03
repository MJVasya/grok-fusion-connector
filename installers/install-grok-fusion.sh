#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not use sudo. Run as your login user so files land in ~/.grok"
  exit 1
fi

URL="${FUSION_MCP_URL:-http://127.0.0.1:27182/mcp}"
CONNECTOR_DIR="${HOME}/.grok/mcp/fusion"
mkdir -p "$CONNECTOR_DIR"

echo "== Grok Fusion MCP installer =="
echo "Target: $URL"

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CLIENT=""
for c in \
  "${GROK_FUSION_LIBEXEC:-}/mcp-client/fusion_mcp_client.py" \
  "${ROOT}/mcp-client/fusion_mcp_client.py" \
  "${ROOT}/libexec/mcp-client/fusion_mcp_client.py"
do
  [[ -n "$c" && -f "$c" ]] && CLIENT="$c" && break
done

if [[ -z "$CLIENT" ]]; then
  echo "ERROR: fusion_mcp_client.py not found next to installer"
  exit 1
fi

cp "$CLIENT" "${CONNECTOR_DIR}/fusion_mcp_client.py"

echo
echo "== Probe Fusion MCP =="
if python3 "$CLIENT" probe >"${CONNECTOR_DIR}/last-probe.json" 2>"${CONNECTOR_DIR}/last-probe.err"; then
  echo "Fusion MCP reachable."
else
  echo "WARN: Fusion MCP not answering (${URL})."
  echo "      Start Fusion and enable Preferences → General → API → Fusion MCP Server."
  echo "      Installer continues."
fi

cat > "${CONNECTOR_DIR}/manifest.json" << EOF
{
  "name": "fusion360",
  "version": "1.1.0",
  "description": "Official Autodesk Fusion MCP (local Streamable HTTP)",
  "transport": { "type": "http", "url": "${URL}" }
}
EOF

mkdir -p "${HOME}/.grok"
TOML="${HOME}/.grok/config.toml"
if [[ -f "$TOML" ]] && grep -q '\[mcp_servers.fusion360\]' "$TOML"; then
  echo "config.toml already has [mcp_servers.fusion360]"
else
  printf '\n[mcp_servers.fusion360]\nurl = "%s"\n' "$URL" >> "$TOML"
  echo "Wrote ${TOML} [mcp_servers.fusion360]"
fi

if command -v grok >/dev/null 2>&1; then
  grok mcp add --transport http fusion360 "$URL" >/dev/null 2>&1 || true
fi

echo
echo "Next: start-fusion-grok-stack   # prints GROK_CONNECTOR_URL"
echo "Stop: stop-fusion-grok-stack"
