# Install, run, update, remove

## New install (Mac)

1. Fusion running → Preferences → General → API → **Fusion MCP Server**.
2. `cloudflared` on PATH (`brew install cloudflare/cloudflare/cloudflared`).
3. Install the connector:

```bash
brew tap mjvasya/grok
brew install --HEAD mjvasya/grok/grok-fusion-connector
install-grok-fusion.sh
```

`--HEAD` is required on **install**. `brew reinstall` does **not** take `--HEAD`. Refresh with `brew reinstall --fetch-HEAD mjvasya/grok/grok-fusion-connector`. Never use `sudo` on these commands.

## After install (daily)

Do **not** rerun `install-grok-fusion.sh`. Each session:

1. Fusion open, Preferences → General → API → Fusion MCP Server.
2. `start-fusion-grok-stack` (no sudo) — starts the hidden bridge + Cloudflare tunnel and prints `GROK_CONNECTOR_URL`.
3. If you use a grok.com **Custom** connector, paste that URL. The trycloudflare hostname changes every start.
4. When done: `stop-fusion-grok-stack`.

The Grok catalog **Fusion360** connector does **not** need this stack — only Fusion with MCP enabled.

## Run (hidden stack + Grok URL)

```bash
start-fusion-grok-stack
```

From a git clone:

```bash
bash installers/start-fusion-grok-stack.sh
```

Prints:

```
GROK_CONNECTOR_URL=https://<name>.trycloudflare.com/mcp
```

Paste that URL into grok.com/connectors → Custom. Hostname changes every launch.

State files: `~/.grok/fusion-stack/` (`bridge.pid`, `cloudflared.pid`, `cloudflared.log`, `connector.url`).

## Kill PIDs

```bash
stop-fusion-grok-stack
```

Manual:

```bash
kill "$(cat ~/.grok/fusion-stack/bridge.pid)"
kill "$(cat ~/.grok/fusion-stack/cloudflared.pid)"
```

## Update

```bash
stop-fusion-grok-stack
brew update
brew reinstall --fetch-HEAD mjvasya/grok/grok-fusion-connector
start-fusion-grok-stack
```

Then replace the Custom connector URL (quick tunnel host is new).

## Remove

```bash
stop-fusion-grok-stack
brew uninstall grok-fusion-connector
brew untap mjvasya/grok
rm -rf ~/.grok/fusion-stack ~/.grok/mcp/fusion
```

Edit `~/.grok/config.toml` and delete `[mcp_servers.fusion360]` if present. Remove the Custom connector on grok.com.
