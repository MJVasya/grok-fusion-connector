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

`--HEAD` is required. `brew update` alone does **not** refresh HEAD source.

## Run (hidden stack + Grok URL)

```bash
bash "$(brew --prefix)/opt/grok-fusion-connector/libexec/installers/start-fusion-grok-stack.sh"
```

From a git clone:

```bash
bash installers/start-fusion-grok-stack.sh
```

Prints:

```
GROK_CONNECTOR_URL=https://<name>.trycloudflare.com/mcp
PIDs: bridge=<PID> cloudflared=<PID>
```

Paste that URL into grok.com/connectors → Custom. Hostname changes every launch.

State files: `~/.grok/fusion-stack/` (`bridge.pid`, `cloudflared.pid`, `cloudflared.log`, `connector.url`).

## Kill PIDs

Preferred:

```bash
bash installers/stop-fusion-grok-stack.sh
```

Manual:

```bash
kill "$(cat ~/.grok/fusion-stack/bridge.pid)"
kill "$(cat ~/.grok/fusion-stack/cloudflared.pid)"
rm -f ~/.grok/fusion-stack/bridge.pid ~/.grok/fusion-stack/cloudflared.pid
```

If a terminal is still in the foreground:

```bash
# Ctrl-C in that window, or:
lsof -nP -iTCP:18782 -sTCP:LISTEN
kill <PID>
pgrep -lf cloudflared
kill <PID>
```

## Update

```bash
bash installers/stop-fusion-grok-stack.sh
brew update
brew upgrade --fetch-HEAD mjvasya/grok/grok-fusion-connector
# if brew says already installed:
brew reinstall --HEAD --fetch-HEAD mjvasya/grok/grok-fusion-connector
install-grok-fusion.sh
bash "$(brew --prefix)/opt/grok-fusion-connector/libexec/installers/start-fusion-grok-stack.sh"
```

Then replace the Custom connector URL (quick tunnel host is new).

## Remove

```bash
bash installers/stop-fusion-grok-stack.sh
brew uninstall grok-fusion-connector
brew untap mjvasya/grok
rm -rf ~/.grok/fusion-stack ~/.grok/mcp/fusion
```

Edit `~/.grok/config.toml` and delete `[mcp_servers.fusion360]` if present. Remove the Custom connector on grok.com.
