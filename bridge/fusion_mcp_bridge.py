#!/usr/bin/env python3
"""Local Host-rewrite proxy for Autodesk Fusion MCP.

Grok/cloudflared  →  http://127.0.0.1:18782/mcp
                  →  this bridge (accepts any Host)
                  →  http://127.0.0.1:27182/mcp  Host: 127.0.0.1:27182
"""

from __future__ import annotations

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

DEFAULT_LISTEN = "127.0.0.1"
DEFAULT_PORT = 18782
DEFAULT_UPSTREAM = "http://127.0.0.1:27182"
UPSTREAM_HOST = "127.0.0.1:27182"

HOP = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "host",
    "content-length",
}


class Bridge(BaseHTTPRequestHandler):
    server_version = "GrokFusionMCPBridge/1.2"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _upstream_url(self) -> str:
        path = self.path if self.path.startswith("/") else "/" + self.path
        if path in ("/", ""):
            path = "/mcp"
        return self.server.upstream.rstrip("/") + path

    def _forward(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else b""

        headers = {}
        for k, v in self.headers.items():
            lk = k.lower()
            if lk in HOP:
                continue
            headers[k] = v
        headers["Host"] = UPSTREAM_HOST
        headers.setdefault("Accept", "application/json, text/event-stream")
        headers.setdefault("Content-Type", "application/json")
        headers.pop("Origin", None)
        headers.pop("origin", None)
        headers.pop("Referer", None)
        headers.pop("referer", None)

        req = Request(self._upstream_url(), data=body or None, headers=headers, method=self.command)
        try:
            with urlopen(req, timeout=120) as resp:
                raw = resp.read()
                code = resp.status
                out_headers = {k: v for k, v in resp.headers.items() if k.lower() not in HOP}
        except HTTPError as e:
            raw = e.read() if e.fp else str(e).encode()
            code = e.code
            out_headers = {k: v for k, v in (e.headers.items() if e.headers else []) if k.lower() not in HOP}
        except URLError as e:
            raw = json.dumps({"error": f"upstream unreachable: {e.reason}"}).encode()
            code = 502
            out_headers = {"Content-Type": "application/json"}

        self.send_response(code)
        if "Content-Type" not in {k.title() for k in out_headers}:
            self.send_header("Content-Type", "application/json")
        for k, v in out_headers.items():
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(raw)

    def do_GET(self):
        self._forward()

    def do_POST(self):
        self._forward()

    def do_HEAD(self):
        self._forward()

    def do_DELETE(self):
        self._forward()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, HEAD, OPTIONS, DELETE")
        self.end_headers()


def main():
    p = argparse.ArgumentParser(description="Fusion MCP Host-rewrite bridge")
    p.add_argument("--listen", default=DEFAULT_LISTEN)
    p.add_argument("--port", type=int, default=DEFAULT_PORT)
    p.add_argument("--upstream", default=DEFAULT_UPSTREAM)
    args = p.parse_args()

    httpd = ThreadingHTTPServer((args.listen, args.port), Bridge)
    httpd.upstream = args.upstream
    print(
        f"Grok Fusion MCP bridge  http://{args.listen}:{args.port}/mcp  ->  {args.upstream}/mcp",
        flush=True,
    )
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped", flush=True)


if __name__ == "__main__":
    main()
