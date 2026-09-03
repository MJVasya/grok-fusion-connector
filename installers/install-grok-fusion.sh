#!/usr/bin/env bash
set -euo pipefail

echo "Installing Grok Fusion MCP Connector..."

CONNECTOR_DIR="${HOME}/.grok/mcp/fusion"
mkdir -p "$CONNECTOR_DIR"

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Homebrew prefix layout: bin/install-grok-fusion.sh + libexec/{mcp-client,fusion-addin}
if [[ -d "${SCRIPT_DIR}/../libexec/fusion-addin" ]]; then
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  ADDIN_SRC="${REPO_ROOT}/libexec/fusion-addin"
  CLIENT_SRC="${REPO_ROOT}/libexec/mcp-client"
elif [[ -d "${REPO_ROOT}/fusion-addin/FusionMCPBridge" ]]; then
  ADDIN_SRC="${REPO_ROOT}/fusion-addin/FusionMCPBridge"
  CLIENT_SRC="${REPO_ROOT}/mcp-client"
else
  ADDIN_SRC=""
  CLIENT_SRC=""
fi

cat > "${CONNECTOR_DIR}/manifest.json" << 'EOF'
{
  "name": "fusion360",
  "version": "1.0.0",
  "description": "Fusion 360 MCP connector for Grok (Claude-compatible)",
  "transport": {
    "type": "http",
    "url": "http://127.0.0.1:27182/mcp"
  },
  "tools": [
    {
      "name": "fusion_mcp_execute",
      "description": "Execute Python script inside Fusion 360",
      "inputSchema": {
        "type": "object",
        "properties": {
          "script": { "type": "string" }
        },
        "required": ["script"]
      }
    },
    {
      "name": "fusion_mcp_screenshot",
      "description": "Capture active Fusion viewport",
      "inputSchema": {
        "type": "object",
        "properties": {
          "width": { "type": "number" },
          "height": { "type": "number" }
        }
      }
    }
  ]
}
EOF

echo "Manifest written to ${CONNECTOR_DIR}/manifest.json"

install_addin() {
  local dest=""
  case "$(uname -s)" in
    Darwin)
      dest="${HOME}/Library/Application Support/Autodesk/Autodesk Fusion/API/AddIns/FusionMCPBridge"
      mkdir -p "$(dirname "$dest")"
      ;;
    Linux)
      dest="${HOME}/.local/share/Autodesk/Autodesk Fusion/API/AddIns/FusionMCPBridge"
      mkdir -p "$(dirname "$dest")"
      ;;
    *)
      echo "Copy fusion-addin/FusionMCPBridge into Fusion Scripts and Add-Ins manually on this OS."
      return 0
      ;;
  esac

  if [[ -z "${ADDIN_SRC}" || ! -d "${ADDIN_SRC}" ]]; then
    echo "Add-in source not found next to installer; skip copy."
    return 0
  fi

  mkdir -p "$dest"
  if [[ -f "${ADDIN_SRC}/FusionMCPBridge.py" ]]; then
    cp -R "${ADDIN_SRC}/." "$dest/"
  elif [[ -f "${ADDIN_SRC}/FusionMCPBridge/FusionMCPBridge.py" ]]; then
    dest="$(dirname "$dest")/FusionMCPBridge"
    mkdir -p "$dest"
    cp -R "${ADDIN_SRC}/FusionMCPBridge/." "$dest/"
  else
    cp -R "${ADDIN_SRC}/." "$dest/"
  fi
  echo "Add-in copied to ${dest}"
}

install_addin

if [[ -n "${CLIENT_SRC}" && -f "${CLIENT_SRC}/fusion_mcp_client.py" ]]; then
  cp "${CLIENT_SRC}/fusion_mcp_client.py" "${CONNECTOR_DIR}/fusion_mcp_client.py"
  [[ -f "${CLIENT_SRC}/requirements.txt" ]] && cp "${CLIENT_SRC}/requirements.txt" "${CONNECTOR_DIR}/requirements.txt"
fi

if command -v grok >/dev/null 2>&1; then
  echo "Registering Fusion connector with Grok CLI..."
  grok mcp add fusion360 "${CONNECTOR_DIR}" || echo "grok mcp add failed; add the connector in Grok UI."
else
  echo "grok CLI not on PATH. Add connector in Grok UI pointing at ${CONNECTOR_DIR}/manifest.json"
fi

echo "Grok Fusion MCP connector installed."
echo "Enable Fusion MCP Server: Fusion → Preferences → General → API → Fusion MCP Server (127.0.0.1:27182)."
echo "Enable add-in: Utilities → Add-Ins → FusionMCPBridge → Run / Run on Startup."
