"""Outbreak detection: turns farmers' reports into alerts for officers to review.

Deliberately plain rules rather than a model, so every alert can be explained
in one sentence and checked by hand. All thresholds live in RULES.

What counts as evidence
  A report names one problem (the top field-guide card). It counts toward an
  alert only if it is *credible*: either the farmer picked the match
  themselves (Lite mode), or the photo model rated its own answer medium or
  high. Low-confidence photo results are stored and shown but never trigger
  anything on their own. Every rule counts distinct farmers, not reports, so
  one worried farmer scanning ten times is still one farmer.

The four signals, per LGA, over the last `window_days`
  new_in_area   >= min_farmers farmers report a problem that had no credible
                report in that LGA in the `baseline_days` before the window.
  surge         >= min_farmers farmers report a problem that is known there,
                at >= surge_ratio times its usual rate.
  unidentified  >= min_farmers farmers get "unclear match" — possibly
                something the field guide doesn't cover.
  spreading     an LGA with a new_in_area or surge signal whose neighbouring
                LGAs also have >= neighbour_farmers farmers reporting the same
                problem. Raises the signal's severity and lists those LGAs.

  "Watch" (not an alert): watch_farmers farmers (default 2) reporting the
  same problem in an LGA in the window. Shown on the map so officers can keep
  an eye on it before it reaches the alert threshold.

Problems that don't spread between farms (nutrient deficiencies, drought,
waterlogging, herbicide injury) are counted for prevalence but never alert.
"""

from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta

RULES = {
    "window_days": 14,
    "baseline_days": 90,
    "min_farmers": 3,
    "watch_farmers": 2,
    "surge_ratio": 3.0,
    "neighbour_farmers": 2,
    "credible_confidence": {"medium", "high"},
}

NON_SPREADING_KINDS = {"deficiency", "disorder"}


@dataclass(frozen=True)
class Report:
    farmer: str  # anonymous id
    reported_at: datetime
    lga: str  # P-code
    card_id: str | None
    source: str  # "photo" or "lite"
    confidence: str | None
    unclear: bool

    @property
    def credible(self):
        return self.source == "lite" or self.confidence in RULES["credible_confidence"]


@dataclass
class Signal:
    kind: str  # new_in_area, surge, unidentified
    lga: str
    card_id: str | None
    farmers: int
    reports: int
    baseline_farmers: int
    first_seen: datetime
    last_seen: datetime
    severity: str  # high, medium
    neighbours: dict = field(default_factory=dict)  # lga -> farmers

    @property
    def key(self):
        return (self.kind, self.lga, self.card_id)


def _spreads(card_id, cards):
    card = cards.get(card_id)
    return card is not None and card["kind"] not in NON_SPREADING_KINDS


def detect(reports, now, cards, neighbours, rules=RULES):
    """Returns (signals, watch) for reports up to `now`.

    `cards` maps card id -> {"kind": ...}; `neighbours` maps LGA -> [LGA].
    `watch` maps (lga, card_id) -> farmers for sub-threshold clusters.
    """
    window_start = now - timedelta(days=rules["window_days"])
    baseline_start = window_start - timedelta(days=rules["baseline_days"])

    recent = defaultdict(list)  # (lga, card) -> [Report]
    baseline = defaultdict(set)  # (lga, card) -> farmers
    unclear = defaultdict(list)  # lga -> [Report]
    for r in reports:
        if r.reported_at > now or r.reported_at < baseline_start:
            continue
        in_window = r.reported_at >= window_start
        if r.unclear:
            if in_window:
                unclear[r.lga].append(r)
            continue
        if not r.credible or not _spreads(r.card_id, cards):
            continue
        if in_window:
            recent[(r.lga, r.card_id)].append(r)
        else:
            baseline[(r.lga, r.card_id)].add(r.farmer)

    def farmers(rs):
        return len({r.farmer for r in rs})

    signals, watch = [], {}
    for (lga, card_id), rs in recent.items():
        n = farmers(rs)
        if n < rules["min_farmers"]:
            if n >= rules["watch_farmers"]:
                watch[(lga, card_id)] = n
            continue
        base = len(baseline[(lga, card_id)])
        # Baseline farmers, scaled to the length of the window.
        expected = base * rules["window_days"] / rules["baseline_days"]
        if base == 0:
            kind, severity = "new_in_area", "high"
        elif n >= rules["surge_ratio"] * max(expected, 1):
            kind, severity = "surge", "medium"
        else:
            continue  # the usual level for this LGA
        signal = Signal(kind, lga, card_id, n, len(rs), base,
                        min(r.reported_at for r in rs), max(r.reported_at for r in rs), severity)
        for other in neighbours.get(lga, []):
            m = farmers(recent.get((other, card_id), []))
            if m >= rules["neighbour_farmers"]:
                signal.neighbours[other] = m
        if signal.neighbours:
            signal.severity = "high"
        signals.append(signal)

    for lga, rs in unclear.items():
        n = farmers(rs)
        if n >= rules["min_farmers"]:
            signals.append(Signal("unidentified", lga, None, n, len(rs), 0,
                                  min(r.reported_at for r in rs),
                                  max(r.reported_at for r in rs), "medium"))
    return signals, watch


def explain(signal, lga_name, problem, rules=RULES):
    """One sentence an officer can check against the raw reports."""
    days = rules["window_days"]
    who = f"{signal.farmers} farmers in {lga_name}"
    if signal.kind == "new_in_area":
        text = (f"{who} reported {problem} in the last {days} days; there were no "
                f"reports of it there in the {rules['baseline_days']} days before.")
    elif signal.kind == "surge":
        text = (f"{who} reported {problem} in the last {days} days, against "
                f"{signal.baseline_farmers} in the {rules['baseline_days']} days before — "
                f"well above its usual level.")
    else:
        text = (f"{who} got no clear match in the last {days} days. This may be a "
                f"problem the field guide doesn't cover; worth a field visit.")
    if signal.neighbours:
        text += f" It is also being reported in {len(signal.neighbours)} neighbouring LGA(s)."
    return text
