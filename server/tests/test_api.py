import json
import urllib.error
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
# Never use the real Supabase settings from server/.env in tests.
for key in ("DATABASE_URL", "SUPABASE_URL", "SUPABASE_ANON_KEY"):
    os.environ[key] = ""
import app  # noqa: E402
from surveillance import auth, config  # noqa: E402


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

    def test_health_and_config_are_public(self):
        self.assertEqual(self.get("/api/health"), (200, {"ok": True}))
        status, body = self.get("/api/config")
        self.assertEqual((status, body["auth"]), (200, False))


class SignInTest(ApiTest):
    """Same server, with officer sign-in switched on and Supabase faked."""

    def setUp(self):
        self._saved = (config.AUTH_REQUIRED, auth._ask_supabase)
        config.AUTH_REQUIRED = True
        auth._cache.clear()

        def fake(token):
            if token == "good":
                return "officer@example.gov.ng"
            raise auth.AuthError("session expired, sign in again")
        auth._ask_supabase = fake

    def tearDown(self):
        config.AUTH_REQUIRED, auth._ask_supabase = self._saved

    def call(self, path, token=None, body=None):
        req = urllib.request.Request(self.base + path, data=body and json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json",
                                              **({"Authorization": f"Bearer {token}"} if token else {})})
        try:
            with urllib.request.urlopen(req, timeout=10) as r:
                return r.status, json.loads(r.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read())

    def get(self, path):
        return self.call(path, token="good")

    def post(self, path, body):
        return self.call(path, token="good", body=body)

    def test_dashboard_data_needs_sign_in(self):
        for path in ("/api/overview", "/api/alerts", "/api/map", "/api/reports/recent",
                     "/api/geo/lgas", "/api/me"):
            self.assertEqual(self.call(path)[0], 401, path)
            self.assertEqual(self.call(path, token="forged")[0], 401, path)
        self.assertEqual(self.call("/api/me", token="good"), (200, {"email": "officer@example.gov.ng"}))

    def test_phones_report_without_sign_in(self):
        status, body = self.call("/api/reports", body=self.phone_batch())
        self.assertEqual((status, body["accepted"]), (200, 1))

    def test_review_needs_sign_in_and_records_officer(self):
        for _ in range(3):
            self.call("/api/reports", body=self.phone_batch())
        alert = [a for a in self.get("/api/alerts")[1] if a["lga"] == "Ikara"][0]
        url = f"/api/alerts/{alert['id']}/review"
        self.assertEqual(self.call(url, body={"status": "dismissed", "note": "x"})[0], 401)
        status, out = self.post(url, {"status": "confirmed", "note": "visited"})
        self.assertEqual((status, out["reviewed_by"]), (200, "officer@example.gov.ng"))

    def test_health_and_config_are_public(self):
        self.assertEqual(self.call("/api/health"), (200, {"ok": True}))
        self.assertEqual(self.call("/api/config")[1]["auth"], True)


if __name__ == "__main__":
    unittest.main()
