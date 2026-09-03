#!/usr/bin/env python3
"""HTTP JSON-RPC client for Autodesk Fusion MCP (127.0.0.1:27182)."""

from __future__ import annotations

import json
import sys
import uuid

import requests

FUSION_MCP_URL = "http://127.0.0.1:27182/mcp"


class FusionMCPClient:
    def __init__(self, url: str = FUSION_MCP_URL):
        self.url = url

    def _rpc(self, method: str, params: dict | None = None):
        payload = {
            "jsonrpc": "2.0",
            "id": str(uuid.uuid4()),
            "method": method,
            "params": params or {},
        }
        resp = requests.post(self.url, json=payload, timeout=60)
        resp.raise_for_status()
        data = resp.json()
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
        result = client.execute_script(sys.argv[2])
        print(json.dumps(result, indent=2))
    elif cmd == "screenshot":
        width = int(sys.argv[2]) if len(sys.argv) > 2 else None
        height = int(sys.argv[3]) if len(sys.argv) > 3 else None
        result = client.screenshot(width, height)
        print(json.dumps(result, indent=2))
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
