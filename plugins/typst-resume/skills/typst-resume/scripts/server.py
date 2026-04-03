#!/usr/bin/env python3
"""
Lightweight HTTP server for the typst-resume template selector.
Zero external dependencies — Python 3 standard library only.

Usage:
    python server.py --preview-dir <path> --port <port>

Routes:
    GET  /              → serves selector.html
    POST /api/select    → writes template selection to events.json
    GET  /api/shutdown  → graceful exit
"""

import argparse
import json
import os
import signal
import socket
import sys
from functools import partial
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path


class SelectorHandler(SimpleHTTPRequestHandler):
    """Handle template selector requests."""

    def __init__(self, *args, preview_dir: str, **kwargs):
        self.preview_dir = Path(preview_dir)
        super().__init__(*args, directory=str(self.preview_dir), **kwargs)

    def do_GET(self):
        if self.path == "/":
            # Serve selector.html
            selector_path = self.preview_dir / "selector.html"
            if selector_path.exists():
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
                self.wfile.write(selector_path.read_bytes())
            else:
                self.send_error(404, "selector.html not found")
        elif self.path == "/api/shutdown":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "shutting down"}).encode())
            # Schedule shutdown after response is sent
            import threading
            threading.Timer(0.5, lambda: os.kill(os.getpid(), signal.SIGTERM)).start()
        elif self.path.endswith(".svg"):
            # Serve SVG preview files
            svg_path = self.preview_dir / self.path.lstrip("/")
            if svg_path.exists():
                self.send_response(200)
                self.send_header("Content-Type", "image/svg+xml")
                self.send_header("Cache-Control", "no-cache")
                self.end_headers()
                self.wfile.write(svg_path.read_bytes())
            else:
                self.send_error(404, f"SVG not found: {self.path}")
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == "/api/select":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            try:
                data = json.loads(body)
                template = data.get("template", "")
                if not template:
                    self.send_error(400, "Missing 'template' field")
                    return

                # Write selection to events.json
                events_path = self.preview_dir / "events.json"
                events_path.write_text(
                    json.dumps({"template": template}, ensure_ascii=False, indent=2)
                )

                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(
                    json.dumps({"status": "ok", "template": template}).encode()
                )
            except (json.JSONDecodeError, KeyError) as e:
                self.send_error(400, f"Invalid request: {e}")
        else:
            self.send_error(404, "Not found")

    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def log_message(self, format, *args):
        """Suppress default logging to keep terminal clean."""
        pass


def find_available_port(start=18420, max_attempts=50):
    """Find an available port starting from the given number."""
    for port in range(start, start + max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(("127.0.0.1", port))
                return port
        except OSError:
            continue
    raise RuntimeError(f"No available port found in range {start}-{start + max_attempts}")


def main():
    parser = argparse.ArgumentParser(description="Template selector HTTP server")
    parser.add_argument("--preview-dir", required=True, help="Path to .preview/ directory")
    parser.add_argument("--port", type=int, default=0, help="Port number (0 = auto-find)")
    args = parser.parse_args()

    preview_dir = Path(args.preview_dir).resolve()
    if not preview_dir.exists():
        print(f"Error: preview directory does not exist: {preview_dir}", file=sys.stderr)
        sys.exit(1)

    port = args.port if args.port > 0 else find_available_port()

    handler = partial(SelectorHandler, preview_dir=str(preview_dir))
    server = HTTPServer(("127.0.0.1", port), handler)

    # Write server info for agent to read
    info = {"port": port, "url": f"http://localhost:{port}", "pid": os.getpid()}
    info_path = preview_dir / "server-info.json"
    info_path.write_text(json.dumps(info, indent=2))

    # Handle graceful shutdown
    def shutdown_handler(signum, frame):
        server.shutdown()

    signal.signal(signal.SIGTERM, shutdown_handler)
    signal.signal(signal.SIGINT, shutdown_handler)

    print(json.dumps(info))
    sys.stdout.flush()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        # Clean up server-info on exit
        if info_path.exists():
            info_path.unlink()


if __name__ == "__main__":
    main()
