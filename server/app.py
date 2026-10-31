"""CropSight Plant Health Watch: the server phones report to, and the
dashboard officers review alerts on. Standard library only.

    python3 app.py                       # http://localhost:8787
    PORT=9000 DB=watch.db python3 app.py
    ALERT_WEBHOOK=https://... python3 app.py   # POST each new alert there

Phones send to POST /api/reports (build the app with
--dart-define=SYNC_ENDPOINT=http://<this machine>:8787/api/reports).
"""

import json
import mimetypes
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from surveillance.store import Surveillance

HERE = Path(__file__).resolve().parent
DASHBOARD = HERE / "dashboard"
MAX_BODY = 1_000_000

watch = Surveillance(os.environ.get("DB", str(HERE / "watch.db")),
                     webhook=os.environ.get("ALERT_WEBHOOK"))


class Handler(BaseHTTPRequestHandler):
    server_version = "CropSightWatch/1"
    timeout = 15  # seconds a client may stall before its connection is dropped

    def _send(self, status, body, content_type="application/json"):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def _json_body(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length < 0 or length > MAX_BODY:
            raise ValueError("bad body length")
        return json.loads(self.rfile.read(length) or b"{}")

    def do_GET(self):
        self._safely(self._get)

    def do_POST(self):
        # Read the body before taking the database lock, so a slow or stalled
        # client only ties up its own connection, not every request.
        try:
            self.body = self._json_body()
        except (ValueError, json.JSONDecodeError) as e:
            return self._send(400, {"error": str(e)})
        except OSError:
            return
        self._safely(self._post)

    def _safely(self, handler):
        # A bug must answer 500, not drop the connection: phones treat a
        # dropped connection as "try again", forever.
        try:
            with watch.lock:
                handler()
        except Exception as e:  # noqa: BLE001
            print(f"error handling {self.command} {self.path}: {e!r}")
            try:
                self._send(500, {"error": "server error"})
            except OSError:
                pass

    def _get(self):
        url = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(url.query).items()}
        path = url.path
        try:
            if path == "/api/overview":
                return self._send(200, watch.overview(int(q.get("days", 30))))
            if path == "/api/alerts":
                return self._send(200, watch.alerts(q.get("status", "open")))
            if path == "/api/map":
                return self._send(200, watch.map_layer())
            if path == "/api/reports/recent":
                return self._send(200, watch.recent_reports(int(q.get("limit", 25))))
            if path in ("/api/geo/states", "/api/geo/lgas"):
                name = path.rsplit("/", 1)[1]
                return self._send(200, (HERE / f"data/{name}.geojson").read_bytes(),
                                  "application/geo+json")
            return self._static(path)
        except (KeyError, ValueError) as e:
            return self._send(400, {"error": str(e)})

    def _post(self):
        path = urlparse(self.path).path
        try:
            body = self.body
            if path == "/api/reports":
                results = body.get("results")
                if not isinstance(results, list):
                    return self._send(400, {"error": "expected {\"results\": [...]}"})
                return self._send(200, watch.ingest(results))
            m = re.fullmatch(r"/api/alerts/(\d+)/review", path)
            if m:
                return self._send(200, watch.review(int(m.group(1)), body.get("status"),
                                                    body.get("note", "")))
            return self._send(404, {"error": "not found"})
        except KeyError:
            return self._send(404, {"error": "no such alert"})
        except (ValueError, json.JSONDecodeError) as e:
            return self._send(400, {"error": str(e)})

    def _static(self, path):
        target = (DASHBOARD / (path.lstrip("/") or "index.html")).resolve()
        if DASHBOARD not in target.parents or not target.is_file():
            return self._send(404, {"error": "not found"})
        kind = mimetypes.guess_type(target.name)[0] or "application/octet-stream"
        return self._send(200, target.read_bytes(), kind)

    def log_message(self, fmt, *args):
        if self.path.startswith("/api/reports") or os.environ.get("VERBOSE"):
            super().log_message(fmt, *args)


class Server(ThreadingHTTPServer):
    # Requests take turns on the database (see Surveillance.lock), so let
    # bursts queue rather than be refused: the default backlog is only 5.
    request_queue_size = 128
    daemon_threads = True


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8787))
    host = os.environ.get("HOST", "0.0.0.0")
    print(f"CropSight Plant Health Watch on http://localhost:{port}")
    Server((host, port), Handler).serve_forever()
