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

Full install / update / remove / kill-PID: [docs/INSTALL.md](docs/INSTALL.md).

## New install

Fusion running + Preferences → General → API → Fusion MCP Server.

```bash
brew tap mjvasya/grok
brew install --HEAD mjvasya/grok/grok-fusion-connector
install-grok-fusion.sh
```

## After install (daily)

Do **not** rerun `install-grok-fusion.sh`. Each session:

1. Fusion open, Preferences → General → API → Fusion MCP Server.
2. `start-fusion-grok-stack` (no sudo) — prints `GROK_CONNECTOR_URL`.
3. grok.com Custom connector: paste that URL (quick-tunnel host changes every start).
4. Done: `stop-fusion-grok-stack`.

Grok catalog **Fusion360** in chat does not need the stack — only Fusion + MCP.

## Run (prints Grok URL + PIDs)

```bash
start-fusion-grok-stack
# or from a clone:
bash installers/start-fusion-grok-stack.sh
```

## Kill PIDs

```bash
stop-fusion-grok-stack
# or:
kill "$(cat ~/.grok/fusion-stack/bridge.pid)"
kill "$(cat ~/.grok/fusion-stack/cloudflared.pid)"
```

## Update

```bash
stop-fusion-grok-stack
brew reinstall --fetch-HEAD mjvasya/grok/grok-fusion-connector
```

## Remove

```bash
stop-fusion-grok-stack
brew uninstall grok-fusion-connector
brew untap mjvasya/grok
rm -rf ~/.grok/fusion-stack ~/.grok/mcp/fusion
```

Tunnel the **bridge** (`:18782`), not Fusion (`:27182`). Connector URL must end in `/mcp`.
