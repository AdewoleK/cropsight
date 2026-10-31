import sys
import tempfile
import unittest
import uuid
from datetime import timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from surveillance.store import Surveillance, utcnow  # noqa: E402
from datetime import datetime  # noqa: E402,F811

IKARA = "NG019005"  # Ikara, Kaduna


def phone_result(farmer, days_ago=1, lga=IKARA, card="tomato_tuta_absoluta", **extra):
    return {
        "id": uuid.uuid4().hex,
        "anonymous_id": farmer,
        "timestamp": (utcnow() - timedelta(days=days_ago)).isoformat() + "Z",
        "source": "lite",
        "confidence": None,
        "unclear": False,
        "state_pcode": "NG019",
        "lga_pcode": lga,
        "cited_cards": [{"id": card, "score": 0.7}],
        **extra,
    }


class StoreTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.w = Surveillance(str(Path(self.tmp.name) / "t.db"))

    def tearDown(self):
        self.w.db.close()
        self.tmp.cleanup()

    def test_lga_code_is_ikara(self):
        self.assertEqual(self.w.lgas[IKARA]["name"], "Ikara")

    def test_rejects_bad_reports(self):
        bad = [
            phone_result("a", lga="NG999999"),
            phone_result("a", card="not_a_card"),
            phone_result("a", source="satellite"),
            phone_result("a", confidence="certain"),
            phone_result("a", days_ago=-3),
            {**phone_result("a"), "cited_cards": []},
        ]
        out = self.w.ingest(bad)
        self.assertEqual(out["accepted"], 0)
        self.assertEqual(len(out["rejected"]), len(bad))

    def test_malformed_entries_are_rejected_not_fatal(self):
        good = phone_result("a")
        out = self.w.ingest([None, 1, "x", [], {**phone_result("b"), "cited_cards": ["fall_armyworm"]},
                             {**phone_result("c"), "lga_pcode": ["NG019005"]},
                             {**phone_result("d"), "timestamp": 12345},
                             {**phone_result("e"), "cited_cards": [{"id": "fall_armyworm", "score": "hi"}]},
                             good])
        self.assertEqual(out["accepted"], 1)
        self.assertEqual(len(out["rejected"]), 8)

    def test_resent_results_are_not_double_counted(self):
        r = phone_result("a")
        self.assertEqual(self.w.ingest([r])["accepted"], 1)
        again = self.w.ingest([r])
        self.assertEqual((again["accepted"], again["duplicates"]), (0, 1))

    def test_three_phones_raise_one_alert_then_updates_it(self):
        out = self.w.ingest([phone_result(f) for f in "abc"])
        self.assertEqual(out["alerts_raised"], 1)
        self.w.ingest([phone_result("d")])
        alerts = self.w.alerts()
        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0]["farmers"], 4)
        self.assertFalse(alerts[0]["simulated"])
        self.assertIn("4 farmers in Ikara", alerts[0]["explanation"])

    def test_dismissed_alert_returns_only_if_more_farmers_report(self):
        self.w.ingest([phone_result(f) for f in "abc"])
        alert_id = self.w.alerts()[0]["id"]
        self.w.review(alert_id, "dismissed", "field visit: it was early blight")
        self.assertEqual(self.w.alerts(), [])
        self.w.ingest([phone_result("a")])  # same farmers again: stays dismissed
        self.assertEqual(self.w.alerts(), [])
        self.w.ingest([phone_result("d")])  # a new farmer: comes back for review
        self.assertEqual(len(self.w.alerts()), 1)

    def test_simulated_flag_follows_the_data(self):
        self.w.ingest([phone_result(f) for f in "abc"], simulated=True)
        self.assertTrue(self.w.alerts()[0]["simulated"])
        self.assertTrue(self.w.overview()["includes_simulated"])
        self.assertEqual(self.w.overview()["real_reports"], 0)

    def test_review_rejects_unknown_status(self):
        self.w.ingest([phone_result(f) for f in "abc"])
        with self.assertRaises(ValueError):
            self.w.review(self.w.alerts()[0]["id"], "ignored", "")

    def test_unhashable_card_id_is_rejected(self):
        out = self.w.ingest([{**phone_result("a"), "cited_cards": [{"id": ["x"], "score": 1}]}])
        self.assertEqual(out["rejected"][0]["reason"], "bad card id")

    def _at(self, days_from_now):
        return utcnow() + timedelta(days=days_from_now)

    def test_new_in_area_becoming_a_surge_stays_one_alert(self):
        # Reports spread over ~6 weeks: early ones fall into the baseline.
        self.w.ingest([phone_result(f"f{i}", days_ago=40 - i * 3) for i in range(14)])
        for day in (0, 20, 30):
            self.w.run_detection(now=self._at(-day))
        open_alerts = self.w.alerts()
        self.assertEqual(len(open_alerts), 1, [a["kind"] for a in open_alerts])

    def test_quiet_alert_closes_itself(self):
        self.w.ingest([phone_result(f, days_ago=30) for f in "abc"])
        self.w.run_detection(now=self._at(-29))
        self.assertEqual(len(self.w.alerts()), 1)
        self.w.run_detection()  # 30 days later, nothing new
        self.assertEqual(self.w.alerts(), [])
        self.assertEqual(self.w.alerts("all")[0]["status"], "closed")

    def test_dismissed_stays_dismissed_at_same_count_after_window(self):
        for d in range(0, 40, 5):  # a steady trickle of the same 3 farmers
            self.w.ingest([{**phone_result(f, days_ago=d), "id": f"{f}{d}"} for f in "abc"])
        self.w.run_detection(now=self._at(-35))
        self.w.review(self.w.alerts()[0]["id"], "dismissed", "known, managed")
        for day in (25, 15, 5, 0):
            self.w.run_detection(now=self._at(-day))
            self.assertEqual(self.w.alerts(), [], f"re-raised {day} days ago")

    def test_provenance_counts_only_credible_triggering_reports(self):
        self.w.ingest([phone_result(f) for f in "abc"], simulated=True)
        self.w.ingest([phone_result("real", source="photo", confidence="low")])
        self.assertEqual(self.w.alerts()[0]["provenance"], "simulated")
        self.w.ingest([phone_result("real2")])
        self.assertEqual(self.w.alerts()[0]["provenance"], "mixed")

    def test_corrected_pick_replaces_the_report(self):
        r = phone_result("a")
        self.w.ingest([r])
        out = self.w.ingest([{**r, "cited_cards": [{"id": "tomato_late_blight", "score": 0.8}]}])
        self.assertEqual(out["updated"], 1)
        rows = self.w.db.execute("SELECT card_id FROM reports").fetchall()
        self.assertEqual([x[0] for x in rows], ["tomato_late_blight"])


if __name__ == "__main__":
    unittest.main()
