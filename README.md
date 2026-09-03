# Grok Fusion MCP Connector

Talks to **Autodesk’s official local Fusion MCP** (`MCP Server Adapter 1.0.0` at `http://127.0.0.1:27182/mcp`). No extra Fusion add-in is required.

## Official tools

| Tool | Use |
|---|---|
| `fusion_mcp_read` | projects, document search, screenshot, API docs, activeCommand |
| `fusion_mcp_execute` | `featureType: script` (must define `def run(_context):`) or document open/close/save |
| `fusion_mcp_update` | undo / redo |
| `fusion_mcp_electronics_read` | electronics design read |

Transport: Streamable HTTP. After `initialize`, every request needs header `Mcp-Session-Id`.

## Install (Mac mini)

Fusion running + Preferences → General → API → Fusion MCP Server.

```bash
git clone https://github.com/MJVasya/grok-fusion-connector.git
cd grok-fusion-connector
python3 mcp-client/fusion_mcp_client.py probe
bash installers/install-grok-fusion.sh
```

Register local Grok CLI / Grok Build:

```bash
grok mcp add --transport http fusion360 http://127.0.0.1:27182/mcp
grok mcp doctor fusion360
```

## grok.com (cloud)

Grok rejects `127.0.0.1`. Tunnel Streamable HTTP:

```bash
cloudflared tunnel --url http://127.0.0.1:27182
```

Then grok.com/connectors → New Connector → Custom → `https://<tunnel>/mcp`

Cloudflare quick tunnels do not support legacy SSE. Fusion uses Streamable HTTP, so Cloudflare is OK.

## Probe a script

```bash
python3 mcp-client/fusion_mcp_client.py exec 'import adsk.core
def run(_c):
    print(adsk.core.Application.get().version)
'
```
