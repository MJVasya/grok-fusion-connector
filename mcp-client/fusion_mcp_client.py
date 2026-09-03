#!/usr/bin/env python3
"""Stdlib client for Autodesk Fusion MCP (streamable HTTP + MCP-Session-Id).

Official tools on MCP Server Adapter 1.0.0:
  fusion_mcp_read / fusion_mcp_execute / fusion_mcp_update / fusion_mcp_electronics_read
No pip deps. Scripts must define: def run(_context):
"""

from __future__ import annotations

import json
import sys
import uuid
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

FUSION_MCP_URL = "http://127.0.0.1:27182/mcp"

VERSION_SCRIPT = """import adsk.core
def run(_context):
    print(adsk.core.Application.get().version)
"""


class FusionMCPClient:
    def __init__(self, url: str = FUSION_MCP_URL):
        self.url = url
        self.session_id: str | None = None
        self._initialized = False

    def _post(self, payload: dict, expect_json: bool = True) -> tuple[Any, dict]:
        data = json.dumps(payload).encode()
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        }
        if self.session_id:
            headers["Mcp-Session-Id"] = self.session_id
        req = Request(self.url, data=data, headers=headers, method="POST")
        try:
            with urlopen(req, timeout=60) as resp:
                raw = resp.read().decode()
                hdrs = {k.lower(): v for k, v in resp.headers.items()}
        except HTTPError as e:
            raw = e.read().decode() if e.fp else str(e)
            raise RuntimeError(f"HTTP {e.code}: {raw[:500]}") from e
        except URLError as e:
            raise RuntimeError(
                f"Cannot reach {self.url} ({e.reason}). "
                "Fusion must be running with Preferences → General → API → Fusion MCP Server."
            ) from e
        sid = hdrs.get("mcp-session-id")
        if sid:
            self.session_id = sid.strip()
        if not expect_json or not raw:
            return raw, hdrs
        try:
            return json.loads(raw), hdrs
        except json.JSONDecodeError:
            return raw, hdrs

    def initialize(self) -> dict:
        body, _ = self._post(
            {
                "jsonrpc": "2.0",
                "id": str(uuid.uuid4()),
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "grok-fusion-connector", "version": "1.1.0"},
                },
            }
        )
        if isinstance(body, dict) and "error" in body:
            raise RuntimeError(body["error"])
        self._post({"jsonrpc": "2.0", "method": "notifications/initialized"}, expect_json=False)
        self._initialized = True
        return body.get("result", body) if isinstance(body, dict) else {"raw": body}

    def _rpc(self, method: str, params: dict | None = None):
        if not self._initialized:
            self.initialize()
        body, _ = self._post(
            {
                "jsonrpc": "2.0",
                "id": str(uuid.uuid4()),
                "method": method,
                "params": params or {},
            }
        )
        if isinstance(body, dict) and "error" in body:
            raise RuntimeError(body["error"])
        return body.get("result") if isinstance(body, dict) else body

    def list_tools(self):
        return self._rpc("tools/list")

    def call_tool(self, name: str, arguments: dict):
        return self._rpc("tools/call", {"name": name, "arguments": arguments})

    def execute_script(self, script: str):
        if "def run(" not in script:
            script = "def run(_context):\n    " + script.replace("\n", "\n    ")
        return self.call_tool(
            "fusion_mcp_execute",
            {"featureType": "script", "object": {"script": script}},
        )

    def screenshot(self, width: int | None = None, height: int | None = None, direction: str = "current"):
        args: dict[str, Any] = {"queryType": "screenshot", "direction": direction}
        if width is not None:
            args["width"] = width
        if height is not None:
            args["height"] = height
        return self.call_tool("fusion_mcp_read", args)

    def probe(self) -> dict:
        info = self.initialize()
        tools = self.list_tools()
        names = [t.get("name") for t in (tools.get("tools") or [])] if isinstance(tools, dict) else []
        exec_result = None
        if "fusion_mcp_execute" in names:
            try:
                exec_result = self.execute_script(VERSION_SCRIPT)
            except Exception as e:
                exec_result = {"error": str(e)}
        return {
            "ok": True,
            "session_id": self.session_id,
            "server": info,
            "tools": names,
            "execute_probe": exec_result,
        }


def main():
    client = FusionMCPClient()
    if len(sys.argv) < 2:
        print("Usage:")
        print("  fusion_mcp_client.py probe")
        print("  fusion_mcp_client.py list-tools")
        print("  fusion_mcp_client.py exec '<python with def run(_context)>'")
        print("  fusion_mcp_client.py screenshot [width] [height] [direction]")
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "probe":
        print(json.dumps(client.probe(), indent=2))
    elif cmd == "list-tools":
        print(json.dumps(client.list_tools(), indent=2))
    elif cmd == "exec":
        if len(sys.argv) < 3:
            sys.exit("missing script")
        print(json.dumps(client.execute_script(sys.argv[2]), indent=2))
    elif cmd == "screenshot":
        w = int(sys.argv[2]) if len(sys.argv) > 2 else None
        h = int(sys.argv[3]) if len(sys.argv) > 3 else None
        d = sys.argv[4] if len(sys.argv) > 4 else "current"
        print(json.dumps(client.screenshot(w, h, d), indent=2))
    else:
        sys.exit(f"Unknown command: {cmd}")


if __name__ == "__main__":
    main()
