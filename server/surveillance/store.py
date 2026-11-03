"""Storage (Postgres on Supabase, or SQLite locally) plus the operations the
API exposes: ingest reports, run detection into reviewable alerts, and the
summaries the dashboard shows."""

import json
import threading
import urllib.request
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

from .db import Database
from .detection import RULES, Report, Signal, detect, explain

DATA = Path(__file__).resolve().parent.parent / "data"

OPEN = ("new", "confirmed")


def utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)


def parse_time(text):
    t = datetime.fromisoformat(text.replace("Z", "+00:00"))
    return t.astimezone(timezone.utc).replace(tzinfo=None) if t.tzinfo else t


class Surveillance:
    def __init__(self, target, webhook=None, schema="watch"):
        """`target` is a SQLite file path or a postgres:// URL."""
        self.db = Database(target, schema=schema)
        # One connection shared by the HTTP server's threads, so every use of
        # it (the API wraps each request in this lock) must be serialised.
        # Re-entrant because ingest() calls run_detection() while holding it.
        self.lock = threading.RLock()
        self.webhook = webhook
        self.cards = json.loads((DATA / "cards.json").read_text())["cards"]
        regions = json.loads((DATA / "regions.json").read_text())
        self.lgas = regions["lgas"]
        self.states = regions["states"]
        self.neighbours = {code: lga["neighbours"] for code, lga in self.lgas.items()}

    # ------------------------------------------------------------------ ingest

    def _validate(self, r):
        # Phones are untrusted: check types before anything else, so one bad
        # entry is rejected on its own instead of failing the whole batch
        # (which the phone would then retry forever).
        if not isinstance(r, dict):
            return "not an object"
        for key in ("id", "anonymous_id", "timestamp", "lga_pcode", "source"):
            if not r.get(key):
                return f"missing {key}"
            if not isinstance(r[key], (str, int)) or isinstance(r[key], bool):
                return f"bad {key}"
        cards = r.get("cited_cards") or []
        if not isinstance(cards, list) or not all(isinstance(c, dict) for c in cards):
            return "bad cited_cards"
        if cards and not isinstance(cards[0].get("score", 0), (int, float)):
            return "bad score"
        if cards and not isinstance(cards[0].get("id"), str):
            return "bad card id"
        if r["lga_pcode"] not in self.lgas:
            return f"unknown LGA {r['lga_pcode']}"
        if r["source"] not in ("photo", "lite"):
            return f"unknown source {r['source']}"
        if r.get("confidence") not in (None, "low", "medium", "high"):
            return f"unknown confidence {r['confidence']}"
        try:
            when = parse_time(r["timestamp"])
        except (ValueError, AttributeError):
            return "bad timestamp"
        if when > utcnow() + timedelta(hours=1):
            return "timestamp in the future"
        if cards and cards[0].get("id") not in self.cards:
            return f"unknown card {cards[0].get('id')}"
        if not cards and not r.get("unclear"):
            return "no cited card"
        return None

    def ingest(self, results, simulated=False):
        """Store a phone's batch. Returns counts and per-result rejections.
        Re-sent results (same farmer + id) are accepted but not double-counted,
        so phones can safely retry after a dropped connection."""
        accepted, duplicates, updated, rejected = 0, 0, 0, []
        now = utcnow().isoformat()
        with self.lock, self.db.transaction():
            for r in results:
                problem = self._validate(r)
                if problem:
                    rejected.append({"id": r.get("id") if isinstance(r, dict) else None,
                                     "reason": problem})
                    continue
                top = (r.get("cited_cards") or [{}])[0]
                lga = self.lgas[r["lga_pcode"]]
                row = (r["anonymous_id"], str(r["id"]), parse_time(r["timestamp"]).isoformat(),
                       now, r["source"], r.get("confidence"), int(bool(r.get("unclear"))),
                       lga["state_pcode"], r["lga_pcode"],
                       None if r.get("unclear") else top.get("id"), top.get("score"),
                       int(simulated))
                old = self.db.execute(
                    "SELECT source, confidence, unclear, lga_pcode, card_id FROM reports "
                    "WHERE farmer=? AND result_id=?", row[:2]).fetchone()
                if old is None:
                    self.db.execute("INSERT INTO reports VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", row)
                    accepted += 1
                elif (old["source"], old["confidence"], old["unclear"], old["lga_pcode"],
                      old["card_id"]) != (row[4], row[5], row[6], row[8], row[9]):
                    # The farmer corrected their pick: replace, don't add.
                    self.db.execute(
                        "UPDATE reports SET source=?, confidence=?, unclear=?, state_pcode=?, "
                        "lga_pcode=?, card_id=?, score=? WHERE farmer=? AND result_id=?",
                        row[4:11] + row[:2])
                    accepted += 1
                    updated += 1
                else:
                    duplicates += 1
        raised = self.run_detection() if accepted else []
        return {"accepted": accepted, "duplicates": duplicates, "updated": updated,
                "rejected": rejected, "alerts_raised": len(raised)}

    # --------------------------------------------------------------- detection

    def _reports(self, since):
        rows = self.db.execute(
            "SELECT * FROM reports WHERE reported_at >= ?", (since.isoformat(),)).fetchall()
        return [Report(r["farmer"], datetime.fromisoformat(r["reported_at"]), r["lga_pcode"],
                       r["card_id"], r["source"], r["confidence"], bool(r["unclear"]))
                for r in rows]

    def run_detection(self, now=None):
        """Turn current signals into alerts, one alert per LGA and problem.

        - An open alert (new or confirmed) is updated in place, including its
          kind, so an outbreak that turns from "new in area" into a "surge"
          stays one alert.
        - A dismissed alert stays dismissed unless more farmers report than
          when it was dismissed.
        - Any alert whose signal has been quiet for a full window is closed,
          so a later recurrence is raised fresh.
        Returns newly raised alert ids."""
        now = now or utcnow()
        since = now - timedelta(days=RULES["window_days"] + RULES["baseline_days"])
        signals, self.watch = detect(self._reports(since), now, self.cards, self.neighbours)
        raised, live = [], set()
        with self.lock, self.db.transaction():
            for s in signals:
                live.add((s.lga, s.card_id))
                existing = self.db.execute(
                    "SELECT * FROM alerts WHERE lga_pcode=? AND card_id IS NOT DISTINCT FROM ? AND status != 'closed' "
                    "ORDER BY id DESC LIMIT 1", (s.lga, s.card_id)).fetchone()
                fields = (s.kind, s.severity, s.farmers, s.reports, s.baseline_farmers,
                          json.dumps(s.neighbours), s.first_seen.isoformat(),
                          s.last_seen.isoformat(), now.isoformat())
                if existing and existing["status"] in OPEN:
                    self.db.execute(
                        "UPDATE alerts SET kind=?, severity=?, farmers=?, reports=?, "
                        "baseline_farmers=?, neighbours=?, first_seen=?, last_seen=?, updated_at=? "
                        "WHERE id=?", fields + (existing["id"],))
                    continue
                if existing and existing["status"] == "dismissed":
                    if s.farmers <= existing["farmers_at_review"]:
                        continue
                    # More farmers since dismissal: close the old record and
                    # raise a new alert for review.
                    self.db.execute("UPDATE alerts SET status='closed' WHERE id=?",
                                    (existing["id"],))
                cur = self.db.execute(
                    "INSERT INTO alerts (lga_pcode, card_id, kind, severity, farmers, reports, "
                    "baseline_farmers, neighbours, first_seen, last_seen, updated_at, raised_at) "
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?) RETURNING id",
                    (s.lga, s.card_id) + fields + (now.isoformat(),))
                raised.append(cur.fetchone()["id"])
            quiet_since = (now - timedelta(days=RULES["window_days"])).isoformat()
            for row in self.db.execute(
                    "SELECT id, lga_pcode, card_id FROM alerts WHERE status != 'closed' "
                    "AND last_seen < ?", (quiet_since,)).fetchall():
                if (row["lga_pcode"], row["card_id"]) not in live:
                    self.db.execute("UPDATE alerts SET status='closed' WHERE id=?", (row["id"],))
        for alert_id in raised:
            self._notify(alert_id)
        return raised

    def _notify(self, alert_id):
        """POST a new alert to ALERT_WEBHOOK (e.g. an SMS or email gateway).
        Best-effort: the alert is already saved and on the dashboard."""
        if not self.webhook:
            return
        body = json.dumps(self.alert(alert_id)).encode()
        req = urllib.request.Request(self.webhook, data=body,
                                     headers={"Content-Type": "application/json"})
        try:
            urllib.request.urlopen(req, timeout=5)
        except OSError as e:
            print(f"alert webhook failed: {e}")

    # ------------------------------------------------------------------ review

    def review(self, alert_id, status, note, officer=None):
        if status not in ("confirmed", "dismissed"):
            raise ValueError("status must be confirmed or dismissed")
        if not isinstance(note, str) or len(note) > 2000:
            raise ValueError("note must be text, at most 2000 characters")
        with self.lock, self.db.transaction():
            cur = self.db.execute(
                "UPDATE alerts SET status=?, review_note=?, reviewed_at=?, reviewed_by=?, "
                "farmers_at_review=farmers WHERE id=?",
                (status, note, utcnow().isoformat(), officer, alert_id))
        if not cur.rowcount:
            raise KeyError(alert_id)
        return self.alert(alert_id)

    # ----------------------------------------------------------------- reading

    def problem_name(self, card_id):
        if card_id is None:
            return "an unidentified problem"
        card = self.cards.get(card_id)
        return f"{card['crop']}: {card['title']}" if card else card_id

    def _alert_json(self, row):
        lga = self.lgas[row["lga_pcode"]]
        neighbours = json.loads(row["neighbours"])
        a = dict(row)
        a.update(
            lga=lga["name"], state=lga["state"], state_pcode=lga["state_pcode"],
            lat=lga["lat"], lon=lga["lon"], problem=self.problem_name(row["card_id"]),
            neighbours=[{"pcode": k, "name": self.lgas[k]["name"], "farmers": v}
                        for k, v in neighbours.items()],
        )
        signal = Signal(row["kind"], row["lga_pcode"], row["card_id"], row["farmers"],
                        row["reports"], row["baseline_farmers"], None, None, row["severity"],
                        neighbours)
        a["explanation"] = explain(signal, lga["name"], a["problem"])
        a["provenance"] = self.provenance(row)
        a["simulated"] = a["provenance"] == "simulated"
        return a

    def provenance(self, row):
        """Where the farmers behind an alert came from: "phone" (all real),
        "simulated" (all demo data) or "mixed". Counts only the reports that
        triggered it: same LGA and problem, credible, inside its window."""
        end = row["last_seen"]
        start = (datetime.fromisoformat(end) - timedelta(days=RULES["window_days"])).isoformat()
        credible = ("unclear=1" if row["card_id"] is None else
                    "unclear=0 AND (source='lite' OR confidence IN ('medium','high'))")
        kinds = {r["simulated"] for r in self.db.execute(
            f"SELECT DISTINCT simulated FROM reports WHERE lga_pcode=? AND card_id IS NOT DISTINCT FROM ? "
            f"AND {credible} AND reported_at >= ? AND reported_at <= ?",
            (row["lga_pcode"], row["card_id"], start, end))}
        if kinds == {1}:
            return "simulated"
        return "phone" if kinds == {0} else "mixed"

    def alert(self, alert_id):
        row = self.db.execute("SELECT * FROM alerts WHERE id=?", (alert_id,)).fetchone()
        if row is None:
            raise KeyError(alert_id)
        return self._alert_json(row)

    def alerts(self, status="open"):
        rows = self.db.execute("SELECT * FROM alerts ORDER BY id DESC").fetchall()
        if status == "open":
            rows = [r for r in rows if r["status"] in OPEN]
        order = {"high": 0, "medium": 1}
        out = [self._alert_json(r) for r in rows]
        status_order = {"new": 0, "confirmed": 1, "dismissed": 2, "closed": 3}
        out.sort(key=lambda a: (status_order.get(a["status"], 4), order.get(a["severity"], 2)))
        return out

    def overview(self, days=30):
        since = (utcnow() - timedelta(days=days)).isoformat()
        rows = self.db.execute("SELECT * FROM reports WHERE reported_at >= ?", (since,)).fetchall()
        problems = Counter(r["card_id"] for r in rows if r["card_id"])
        by_state = defaultdict(Counter)
        for r in rows:
            if r["card_id"]:
                by_state[r["state_pcode"]][r["card_id"]] += 1
        any_sim = self.db.execute("SELECT 1 FROM reports WHERE simulated=1 LIMIT 1").fetchone()
        return {
            "days": days,
            "reports": len(rows),
            "farmers": len({r["farmer"] for r in rows}),
            "lgas": len({r["lga_pcode"] for r in rows}),
            "states": len({r["state_pcode"] for r in rows}),
            "real_reports": sum(1 for r in rows if not r["simulated"]),
            "open_alerts": len(self.alerts("open")),
            "includes_simulated": bool(any_sim),
            "rules": {k: (sorted(v) if isinstance(v, set) else v) for k, v in RULES.items()},
            "top_problems": [{"card_id": c, "problem": self.problem_name(c), "reports": n}
                             for c, n in problems.most_common(8)],
            "prevalence": sorted(
                ({"state_pcode": s, "state": self.states[s], "reports": sum(c.values()),
                  "top": [{"problem": self.problem_name(k), "reports": n}
                          for k, n in c.most_common(3)]}
                 for s, c in by_state.items()),
                key=lambda x: -x["reports"]),
        }

    def map_layer(self, days=RULES["window_days"]):
        """Per-LGA status for colouring the map: alert > watch > reports."""
        since = (utcnow() - timedelta(days=days)).isoformat()
        out = defaultdict(lambda: {"reports": 0, "farmers": set(), "problems": Counter()})
        for r in self.db.execute("SELECT * FROM reports WHERE reported_at >= ?", (since,)):
            cell = out[r["lga_pcode"]]
            cell["reports"] += 1
            cell["farmers"].add(r["farmer"])
            cell["problems"][self.problem_name(r["card_id"])] += 1
        # Re-run detection on every map refresh (cheap at pilot scale) so
        # alerts and watch levels follow the rolling window even on days
        # with no new reports.
        self.run_detection()
        level = {}
        for (lga, _), _n in self.watch.items():
            level[lga] = "watch"
        for a in self.alerts("open"):
            level[a["lga_pcode"]] = "alert"
            for n in a["neighbours"]:
                level.setdefault(n["pcode"], "watch")
        result = {}
        for lga in set(out) | set(level):
            cell = out.get(lga, {"reports": 0, "farmers": set(), "problems": Counter()})
            info = self.lgas[lga]
            result[lga] = {
                "name": info["name"], "state": info["state"],
                "level": level.get(lga, "reports" if cell["reports"] else "none"),
                "reports": cell["reports"], "farmers": len(cell["farmers"]),
                "top_problem": cell["problems"].most_common(1)[0][0] if cell["problems"] else None,
            }
        return result

    def recent_reports(self, limit=25):
        rows = self.db.execute(
            "SELECT * FROM reports ORDER BY received_at DESC, reported_at DESC LIMIT ?",
            (limit,)).fetchall()
        return [{"reported_at": r["reported_at"], "received_at": r["received_at"],
                 "lga": self.lgas[r["lga_pcode"]]["name"],
                 "state": self.lgas[r["lga_pcode"]]["state"],
                 "problem": "Unclear match" if r["unclear"] else self.problem_name(r["card_id"]),
                 "source": r["source"], "confidence": r["confidence"],
                 "simulated": bool(r["simulated"])} for r in rows]
