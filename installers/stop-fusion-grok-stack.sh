#!/usr/bin/env bash
# Kill hidden bridge + cloudflared started by start-fusion-grok-stack.sh
set -euo pipefail
STATE="${GROK_FUSION_STATE:-$HOME/.grok/fusion-stack}"
killed=0
for name in bridge.pid cloudflared.pid; do
  f="$STATE/$name"
  if [[ -f "$f" ]]; then
    pid="$(cat "$f")"
    if kill "$pid" 2>/dev/null; then
      echo "killed $name PID=$pid"
      killed=1
    else
      echo "stale $name PID=$pid (already dead)"
    fi
    rm -f "$f"
  fi
done
# leftover listeners
for p in $(lsof -tiTCP:18782 -sTCP:LISTEN 2>/dev/null || true); do
  echo "killed leftover :18782 PID=$p"
  kill "$p" 2>/dev/null || true
  killed=1
done
for p in $(pgrep -f 'cloudflared tunnel --url http://127.0.0.1:18782' || true); do
  echo "killed leftover cloudflared PID=$p"
  kill "$p" 2>/dev/null || true
  killed=1
done
[[ "$killed" == "1" ]] || echo "nothing running"
echo "state: $STATE"
