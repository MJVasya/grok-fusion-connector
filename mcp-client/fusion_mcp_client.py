#!/usr/bin/env python3
"""HTTP JSON-RPC client for Autodesk Fusion MCP (streamable HTTP + session)."""

from __future__ import annotations

import json
import sys
import uuid

import requests

FUSION_MCP_URL = "http://127.0.0.1:27182/mcp"


class FusionMCPClient:
    def __init__(self, url: str = FUSION_MCP_URL):
        self.url = url
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream",
            }
        )
        self.session_id: str | None = None
        self._initialized = False

    def _capture_session(self, resp: requests.Response) -> None:
        sid = resp.headers.get("Mcp-Session-Id") or resp.headers.get("MCP-Session-Id")
        if sid:
            self.session_id = sid.strip()
            self.session.headers["Mcp-Session-Id"] = self.session_id

    def initialize(self) -> dict:
        payload = {
            "jsonrpc": "2.0",
            "id": str(uuid.uuid4()),
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "grok-fusion-connector", "version": "1.0.0"},
            },
        }
        resp = self.session.post(self.url, json=payload, timeout=60)
        self._capture_session(resp)
        resp.raise_for_status()
        data = resp.json()
        if self.session_id:
            self.session.post(
                self.url,
                json={"jsonrpc": "2.0", "method": "notifications/initialized"},
                timeout=30,
            )
        self._initialized = True
        return data.get("result", data)

    def _rpc(self, method: str, params: dict | None = None):
        if not self._initialized:
            self.initialize()
        payload = {
            "jsonrpc": "2.0",
            "id": str(uuid.uuid4()),
            "method": method,
            "params": params or {},
        }
        resp = self.session.post(self.url, json=payload, timeout=60)
        self._capture_session(resp)
        resp.raise_for_status()
        try:
            data = resp.json()
        except ValueError as e:
            raise RuntimeError(f"Non-JSON MCP response: {resp.text[:400]}") from e
        if "error" in data:
            raise RuntimeError(f"MCP error: {data['error']}")
        return data.get("result")

    def list_tools(self):
        return self._rpc("tools/list")

    def call_tool(self, name: str, arguments: dict):
        return self._rpc("tools/call", {"name": name, "arguments": arguments})

    def execute_script(self, script: str):
        return self.call_tool("fusion_mcp_execute", {"script": script})

    def screenshot(self, width: int | None = None, height: int | None = None):
        args = {}
        if width is not None:
            args["width"] = width
        if height is not None:
            args["height"] = height
        return self.call_tool("fusion_mcp_screenshot", args)


def main():
    client = FusionMCPClient()

    if len(sys.argv) < 2:
        print("Usage:")
        print("  fusion_mcp_client.py list-tools")
        print("  fusion_mcp_client.py exec '<python_script>'")
        print("  fusion_mcp_client.py screenshot [width] [height]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "list-tools":
        print(json.dumps(client.list_tools(), indent=2))
    elif cmd == "exec":
        if len(sys.argv) < 3:
            print("error: missing script")
            sys.exit(1)
        print(json.dumps(client.execute_script(sys.argv[2]), indent=2))
    elif cmd == "screenshot":
        width = int(sys.argv[2]) if len(sys.argv) > 2 else None
        height = int(sys.argv[3]) if len(sys.argv) > 3 else None
        print(json.dumps(client.screenshot(width, height), indent=2))
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
