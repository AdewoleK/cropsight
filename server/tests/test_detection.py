import sys
import unittest
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from surveillance.detection import Report, detect  # noqa: E402

NOW = datetime(2026, 10, 31, 12, 0)
CARDS = {
    "tomato_tuta_absoluta": {"kind": "pest"},
    "fall_armyworm": {"kind": "pest"},
    "nitrogen_deficiency": {"kind": "deficiency"},
}
# A - B - C in a row; D on its own.
NEIGHBOURS = {"A": ["B"], "B": ["A", "C"], "C": ["B"], "D": []}


def report(farmer, days_ago, lga="A", card="tomato_tuta_absoluta",
           source="lite", confidence=None, unclear=False):
    return Report(f"farmer-{farmer}", NOW - timedelta(days=days_ago), lga, card,
                  source, confidence, unclear)


def run(reports):
    return detect(reports, NOW, CARDS, NEIGHBOURS)


class NewInAreaTest(unittest.TestCase):
    def test_three_farmers_with_no_history_raise_new_in_area(self):
        signals, _ = run([report(i, 2) for i in range(3)])
        self.assertEqual([s.kind for s in signals], ["new_in_area"])
        self.assertEqual(signals[0].farmers, 3)
        self.assertEqual(signals[0].severity, "high")

    def test_two_farmers_is_watch_not_alert(self):
        signals, watch = run([report(i, 2) for i in range(2)])
        self.assertEqual(signals, [])
        self.assertEqual(watch, {("A", "tomato_tuta_absoluta"): 2})

    def test_one_farmer_scanning_many_times_is_one_farmer(self):
        signals, watch = run([report(1, d) for d in range(10)])
        self.assertEqual(signals, [])
        self.assertEqual(watch, {})

    def test_reports_outside_window_do_not_count(self):
        signals, _ = run([report(i, 20) for i in range(5)])
        self.assertEqual(signals, [])


class CredibilityTest(unittest.TestCase):
    def test_low_confidence_photos_never_trigger(self):
        signals, _ = run([report(i, 1, source="photo", confidence="low") for i in range(6)])
        self.assertEqual(signals, [])

    def test_medium_and_high_photos_count(self):
        reports = [report(1, 1, source="photo", confidence="medium"),
                   report(2, 1, source="photo", confidence="high"),
                   report(3, 1, source="lite")]
        signals, _ = run(reports)
        self.assertEqual([s.kind for s in signals], ["new_in_area"])

    def test_non_spreading_problems_never_alert(self):
        signals, watch = run([report(i, 1, card="nitrogen_deficiency") for i in range(8)])
        self.assertEqual((signals, watch), ([], {}))


class SurgeTest(unittest.TestCase):
    def test_known_problem_at_usual_level_is_quiet(self):
        # 6 farmers over the 90-day baseline -> ~1 expected per 14 days.
        history = [report(f"old{i}", 20 + i * 12, card="fall_armyworm") for i in range(6)]
        recent = [report(i, 3, card="fall_armyworm") for i in range(2)]
        signals, _ = run(history + recent)
        self.assertEqual(signals, [])

    def test_known_problem_well_above_usual_is_a_surge(self):
        history = [report(f"old{i}", 20 + i * 12, card="fall_armyworm") for i in range(6)]
        recent = [report(i, 3, card="fall_armyworm") for i in range(5)]
        signals, _ = run(history + recent)
        self.assertEqual([s.kind for s in signals], ["surge"])
        self.assertEqual(signals[0].baseline_farmers, 6)

    def test_three_farmers_on_a_busy_baseline_is_not_a_surge(self):
        # 30 farmers over 90 days -> ~4.7 expected per 14 days; 3 is below it.
        history = [report(f"old{i}", 15 + i * 3, card="fall_armyworm") for i in range(30)]
        recent = [report(i, 3, card="fall_armyworm") for i in range(3)]
        signals, _ = run(history + recent)
        self.assertEqual(signals, [])


class SpreadingTest(unittest.TestCase):
    def test_same_problem_next_door_marks_spreading(self):
        reports = [report(i, 2, lga="A") for i in range(4)]
        reports += [report(f"b{i}", 1, lga="B") for i in range(2)]
        signals, watch = run(reports)
        self.assertEqual(len(signals), 1)
        self.assertEqual(signals[0].neighbours, {"B": 2})
        self.assertEqual(watch, {("B", "tomato_tuta_absoluta"): 2})

    def test_far_away_reports_are_not_neighbours(self):
        reports = [report(i, 2, lga="A") for i in range(4)]
        reports += [report(f"c{i}", 1, lga="C") for i in range(3)]
        signals, _ = run(reports)
        by_lga = {s.lga: s for s in signals}
        self.assertEqual(by_lga["A"].neighbours, {})
        self.assertEqual(by_lga["C"].neighbours, {})


class UnidentifiedTest(unittest.TestCase):
    def test_cluster_of_unclear_matches(self):
        signals, _ = run([report(i, 1, card=None, source="photo", confidence="low", unclear=True)
                          for i in range(3)])
        self.assertEqual([s.kind for s in signals], ["unidentified"])

    def test_unclear_results_are_not_counted_as_the_card(self):
        reports = [report(i, 1, source="photo", confidence="high", unclear=True) for i in range(3)]
        signals, _ = run(reports)
        self.assertEqual([s.kind for s in signals], ["unidentified"])


if __name__ == "__main__":
    unittest.main()
