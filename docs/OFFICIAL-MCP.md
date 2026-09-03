# Official Autodesk Fusion MCP (source of truth)

The Autodesk Help GUID `producthelpmcp_tools` currently 404s. Fusion desktop tooling is **dynamic** — discovered at `tools/list`. This file tracks Autodesk’s published servers plus the live tool surface verified against Grok’s Fusion360 connector and `MCP Server Adapter 1.0.0`.

## Two Fusion servers (do not mix)

| | Autodesk Fusion MCP (desktop) | Autodesk Fusion Data MCP (cloud) |
|---|---|---|
| Docs | [Fusion MCP Server](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_FusionDesktopMcp_autodesk_fusion_mcp_server_html) | [Fusion Data MCP](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_FusionCloudMcp_autodesk_fusion_data_mcp_server_html) |
| Connect | [Connecting](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_FusionDesktopMcp_connecting_to_the_fusion_mcp_server_html) | [Connecting](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_FusionCloudMcp_connecting_to_the_fusion_data_mcp_server_html) |
| URL | `http://127.0.0.1:27182/mcp` | `https://developer.api.autodesk.com/fusion/mcp` |
| Auth | none | Autodesk account (CIMD/OAuth) |
| Fusion running | required | not required |
| This repo | **yes** (bridge + client) | no |

Overview: [Fusion MCPs Overview](https://help.autodesk.com/view/fusion360/ENU/?guid=FMCP-OVERVIEW)

## Desktop requirements (Autodesk)

1. Fusion desktop running (not the web client).
2. Preferences → General → API → **Fusion MCP Server (runs locally on this device)**.
3. Client supports Streamable HTTP.
4. Default port `27182` (change the client URL if the preference port changes).

## Protocol

- JSON-RPC 2.0 over Streamable HTTP
- `initialize` (`protocolVersion` `2024-11-05`) → persist `Mcp-Session-Id` → `notifications/initialized` → `tools/list` / `tools/call`
- Fusion rejects a public `Host` header. This repo’s bridge on `:18782` rewrites `Host: 127.0.0.1:27182`.

## Live desktop tools

See [TOOLS.md](TOOLS.md). Names:

- `fusion_mcp_read`
- `fusion_mcp_execute`
- `fusion_mcp_update`
- `fusion_mcp_electronics_read`

Grok catalog connector **Fusion360** is the same four tools.
