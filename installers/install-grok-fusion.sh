#!/usr/bin/env bash
set -euo pipefail

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
  "${ROOT}/mcp-client/fusion_mcp_client.py" \
  "${ROOT}/libexec/mcp-client/fusion_mcp_client.py"
do
  [[ -f "$c" ]] && CLIENT="$c" && break
done

if [[ -z "$CLIENT" ]]; then
  echo "ERROR: fusion_mcp_client.py not found next to installer"
  exit 1
fi

cp "$CLIENT" "${CONNECTOR_DIR}/fusion_mcp_client.py"

echo
echo "== Probe Fusion MCP =="
python3 "$CLIENT" probe | tee "${CONNECTOR_DIR}/last-probe.json"

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
  echo
  echo "== Register Grok CLI =="
  grok mcp add --transport http fusion360 "$URL" || true
  grok mcp list || true
  grok mcp doctor fusion360 || true
else
  echo
  echo "grok CLI not on PATH."
  echo "Local:  grok mcp add --transport http fusion360 $URL"
  echo "grok.com rejects 127.0.0.1. Tunnel:"
  echo "  cloudflared tunnel --url http://127.0.0.1:27182"
  echo "  Then grok.com/connectors → Custom → https://YOUR-TUNNEL/mcp"
fi

echo
echo "Done. Keep Fusion running."
echo "Scripts must define: def run(_context):"
