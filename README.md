# Grok Fusion MCP Connector (Claude-compatible)

[![Release](https://img.shields.io/github/v/release/MJVasya/grok-fusion-connector)](https://github.com/MJVasya/grok-fusion-connector/releases)
[![License](https://img.shields.io/github/license/MJVasya/grok-fusion-connector)](LICENSE)

Fusion MCP connector pack for Grok, modeled after the Claude Fusion connector.

- Autodesk Fusion MCP server (HTTP, default `http://127.0.0.1:27182/mcp`)
- Fusion add-in `FusionMCPBridge` helpers:
  - `fusion_mcp_execute`
  - `fusion_mcp_screenshot`
- Grok MCP manifest + CLI installer
- Homebrew tap: [`mjvasya/homebrew-grok`](https://github.com/MJVasya/homebrew-grok)

The HTTP MCP endpoint is **hosted by Fusion**, not by this repo. Enable it in Fusion before connecting Grok.

## Install via Homebrew

```bash
brew tap mjvasya/grok
brew install grok-fusion-connector
install-grok-fusion.sh
```

## Manual install (macOS)

1. Copy `fusion-addin/FusionMCPBridge` to:

   ```bash
   ~/Library/Application\\ Support/Autodesk/Autodesk\\ Fusion/API/AddIns/
   ```

2. Enable the add-in in Fusion (Utilities → Scripts and Add-Ins).
3. Enable Fusion MCP Server:

   Fusion → Preferences → General → API → **Fusion MCP Server (runs locally on this device)**

   Default URL: `http://127.0.0.1:27182/mcp`

4. Run:

   ```bash
   bash installers/install-grok-fusion.sh
   ```

## Usage

From Grok / the Python client:

```bash
python3 mcp-client/fusion_mcp_client.py list-tools
```

- `fusion_mcp_execute`

  ```json
  { "script": "import adsk.core\napp = adsk.core.Application.get(); print(app.version)" }
  ```

- `fusion_mcp_screenshot`

  ```json
  { "width": 1280, "height": 720 }
  ```

Fusion must be running with MCP enabled or the client will get connection refused.

## Release / Homebrew SHA

1. Tag `vX.Y.Z` and push the tag (creates the GitHub archive Homebrew uses).
2. Run workflow **Update Homebrew SHA** with that tag.
3. Paste the printed `sha256` into `Formula/grok-fusion-connector.rb` in `homebrew-grok`.
