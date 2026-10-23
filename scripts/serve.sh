#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Ingo Ruhnke <grumbel@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Serves the site directory over HTTP and opens it in a browser.
#
# Env: PKG (directory to serve, default: current), FA18_PORT (default 8765),
#      BROWSER.
set -euo pipefail

case "${1:-}" in
  --help|-h)
    echo "Usage: serve.sh"
    echo "Env: PKG, FA18_PORT, BROWSER"
    exit 0
    ;;
  "") ;;
  *)
    echo "error: unexpected argument: $1 (try --help)" >&2
    exit 1
    ;;
esac

if [ -n "${PKG:-}" ]; then
  cd "$PKG"
fi

port="${FA18_PORT:-8765}"

port_file=$(mktemp)
server_pid=
trap 'kill "$server_pid" 2>/dev/null || true; rm -f "$port_file"' EXIT

python3 -c '
import http.server, socketserver, sys
port_file, port = sys.argv[1], int(sys.argv[2])

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm"}
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        super().end_headers()
    def log_message(self, *a):
        pass

socketserver.TCPServer.allow_reuse_address = True
try:
    httpd = socketserver.TCPServer(("127.0.0.1", port), NoCacheHandler)
except OSError as e:
    sys.stderr.write("error: cannot bind 127.0.0.1:%s (%s); set FA18_PORT to a free port\n" % (port, e))
    sys.exit(1)
open(port_file, "w").write(str(httpd.server_address[1]))
httpd.serve_forever()
' "$port_file" "$port" &
server_pid=$!

for _ in $(seq 1 50); do
  [ -s "$port_file" ] && break
  sleep 0.05
done
if [ ! -s "$port_file" ]; then
  echo "error: the local HTTP server did not start on port $port" >&2
  exit 1
fi
port=$(cat "$port_file")
url="http://127.0.0.1:${port}/?v=$(date +%s)"

echo "Serving FA-18 Interceptor site at $url  (Ctrl-C to stop)"

if [ -n "${BROWSER:-}" ]; then
  "$BROWSER" "$url" >/dev/null 2>&1 || true
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$url" >/dev/null 2>&1 || true
fi

wait "$server_pid"
