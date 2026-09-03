# Grok Fusion MCP Connector

Talks to Autodesk’s official local Fusion MCP (`MCP Server Adapter 1.0.0` at `http://127.0.0.1:27182/mcp`). No extra Fusion add-in. Tooling is **dynamic** (Autodesk: discover at connect time).

Official docs:

- [Fusion MCP Server](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_FusionDesktopMcp_autodesk_fusion_mcp_server_html)
- [Connecting](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_FusionDesktopMcp_connecting_to_the_fusion_mcp_server_html)
- [Fusion MCPs overview](https://help.autodesk.com/view/fusion360/ENU/?guid=FMCP-OVERVIEW)

`producthelpmcp_tools` 404s. Live schemas: [docs/TOOLS.md](docs/TOOLS.md) · servers: [docs/OFFICIAL-MCP.md](docs/OFFICIAL-MCP.md).

## Official tools (live desktop)

| Tool | Use |
|---|---|
| `fusion_mcp_read` | `queryType`: projects, document (search/open/recent), screenshot, apiDocumentation, activeCommand |
| `fusion_mcp_execute` | `featureType: script` with `def run(_context: str):` or document open/close/save |
| `fusion_mcp_update` | undo / redo |
| `fusion_mcp_electronics_read` | electronics entities (read-only) |

Transport: Streamable HTTP. After `initialize`, every request needs `Mcp-Session-Id`. API lengths are **cm**.

## Install

Fusion running + Preferences → General → API → Fusion MCP Server.

```bash
brew tap mjvasya/grok
brew install --HEAD mjvasya/grok/grok-fusion-connector
install-grok-fusion.sh
```

Or clone this repo and run `python3 mcp-client/fusion_mcp_client.py probe`.

## Run

```bash
start-fusion-grok-bridge          # http://127.0.0.1:18782/mcp → Fusion :27182
```

Local Grok CLI:

```bash
grok mcp add --transport http fusion360 http://127.0.0.1:18782/mcp
```

## grok.com via Cloudflare Tunnel (verified)

Do **not** point the tunnel at `:27182` (Fusion rejects public `Host`). Point it at the **bridge**.

```bash
start-fusion-grok-bridge
cloudflared tunnel --url http://127.0.0.1:18782
```

Custom connector URL: `https://<name>.trycloudflare.com/mcp`

Verified working with Grok Custom Connector + Cloudflare quick tunnel when:

- Fusion MCP is on
- bridge is listening on `:18782`
- cloudflared targets the bridge
- connector URL ends in `/mcp`

Grok catalog **Fusion360** connector is the same four tools without a tunnel.
