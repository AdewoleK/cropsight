import json
import os
import sys
import tempfile
import threading
import unittest
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

TMP = tempfile.TemporaryDirectory()
os.environ["DB"] = str(Path(TMP.name) / "api.db")
import app  # noqa: E402


class ApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = app.Server(("127.0.0.1", 0), app.Handler)
        cls.base = f"http://127.0.0.1:{cls.server.server_address[1]}"
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()

    def get(self, path):
        with urllib.request.urlopen(self.base + path, timeout=10) as r:
            return r.status, json.loads(r.read())

    def post(self, path, body):
        req = urllib.request.Request(self.base + path, data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, json.loads(r.read())

    def phone_batch(self):
        return {"results": [{
            "id": uuid.uuid4().hex, "anonymous_id": uuid.uuid4().hex,
            "timestamp": datetime.now(timezone.utc).isoformat(), "source": "lite",
            "confidence": None, "unclear": False, "lga_pcode": "NG019005",
            "cited_cards": [{"id": "tomato_tuta_absoluta", "score": 0.8}],
        }]}

    def test_concurrent_dashboard_and_phone_traffic(self):
        # The dashboard fires four requests at once every 10 s while phones
        # upload; all of them share one SQLite connection.
        paths = ["/api/overview", "/api/alerts?status=all", "/api/map", "/api/reports/recent"]

        def call(i):
            if i % 5 == 0:
                return self.post("/api/reports", self.phone_batch())[0]
            return self.get(paths[i % len(paths)])[0]

        with ThreadPoolExecutor(max_workers=16) as pool:
            statuses = list(pool.map(call, range(60)))
        self.assertEqual(set(statuses), {200})

    def test_phone_upload_raises_alert_and_review_closes_it(self):
        for _ in range(3):
            status, body = self.post("/api/reports", self.phone_batch())
            self.assertEqual((status, body["accepted"]), (200, 1))
        _, alerts = self.get("/api/alerts")
        ikara = [a for a in alerts if a["lga"] == "Ikara"]
        self.assertTrue(ikara)
        status, reviewed = self.post(f"/api/alerts/{ikara[0]['id']}/review",
                                     {"status": "confirmed", "note": "officer visited"})
        self.assertEqual((status, reviewed["status"]), (200, "confirmed"))

    def test_bad_payload_is_rejected_cleanly(self):
        req = urllib.request.Request(self.base + "/api/reports", data=b'{"nope": 1}',
                                     headers={"Content-Type": "application/json"})
        with self.assertRaises(urllib.error.HTTPError) as e:
            urllib.request.urlopen(req, timeout=10)
        self.assertEqual(e.exception.code, 400)

    def test_stalled_upload_does_not_freeze_other_requests(self):
        import socket
        port = self.server.server_address[1]
        stalled = socket.create_connection(("127.0.0.1", port))
        stalled.sendall(b"POST /api/reports HTTP/1.1\r\nHost: x\r\n"
                        b"Content-Type: application/json\r\nContent-Length: 500\r\n\r\n{")
        try:
            status, _ = self.get("/api/overview")  # urlopen timeout is 10 s
            self.assertEqual(status, 200)
        finally:
            stalled.close()

    def test_negative_content_length_is_rejected(self):
        import http.client
        conn = http.client.HTTPConnection("127.0.0.1", self.server.server_address[1], timeout=5)
        conn.putrequest("POST", "/api/reports")
        conn.putheader("Content-Length", "-1")
        conn.endheaders()
        self.assertEqual(conn.getresponse().status, 400)


if __name__ == "__main__":
    unittest.main()
