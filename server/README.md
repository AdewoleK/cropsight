# CropSight Plant Health Watch

The server CropSight phones report to, and the dashboard plant-health officers
use to review outbreak alerts. Python standard library only — no packages to
install.

```bash
cd server
python3 app.py                  # dashboard at http://localhost:8787
python3 simulate.py             # load labelled demo data (optional)
python3 -m unittest discover -s tests
```

Point a phone build at it:

```bash
flutter run --dart-define=SYNC_ENDPOINT=http://<this-machine>:8787/api/reports
```

On the phone: Settings → Disease reporting → turn on "Share my results" and
pick the state and LGA. Nothing is sent until both are done.

## What a phone sends

```json
{"results": [{
  "id": "1793408695184", "anonymous_id": "random per install",
  "timestamp": "2026-10-31T01:04:55Z", "source": "lite",
  "confidence": null, "unclear": false,
  "state_pcode": "NG019", "lga_pcode": "NG019005",
  "cited_cards": [{"id": "tomato_tuta_absoluta", "score": 0.88}]
}]}
```

No photo, no name, no phone number, no GPS, no free text. Locations are LGA
P-codes from OCHA's COD-AB boundaries (`data/regions.json`).

## How alerts are raised

See `surveillance/detection.py` — plain rules, each alert explained in one
sentence:

| Signal | When |
|---|---|
| New in area | 3+ farmers in an LGA report a problem with no reports there in the previous 90 days |
| Surge | 3+ farmers report a known problem at 3× or more its usual rate |
| Unidentified | 3+ farmers in an LGA get "unclear match" |
| Spreading | The same problem is reported by 2+ farmers in a neighbouring LGA |
| Watch (map only) | 2 farmers — not yet an alert |

Only credible reports count (farmer-picked in Lite mode, or photo results the
AI rated medium/high), and everything counts distinct farmers, not scans.
Deficiencies and other non-spreading problems never alert. An officer confirms
or dismisses every alert; a dismissed alert only returns if more farmers report.

New alerts can be pushed to `ALERT_WEBHOOK` (e.g. an SMS or email gateway).

## Before real use

This is a pilot. For production it needs, at minimum: HTTPS, sign-in for
officers (the dashboard and review endpoint are open), rate limiting on
`/api/reports`, a managed database with backups, and a data-protection review
under the Nigeria Data Protection Act 2023.

Reports are not authenticated. "Distinct farmers" trusts the random ID each
phone sends, so one person could fake several farmers and raise an alert.
That is why every alert needs officer review. Before scale, phones should
register once (e.g. a per-install key issued at first sync, or a
USSD/phone-number check run by the agency) and reports should be signed.

## Data

- `data/regions.json`, `data/*.geojson` — built by `tool/build_regions.py`
  from OCHA COD-AB Nigeria boundaries (HDX, CC BY-IGO).
- `data/cards.json` — the app's field guide, exported by
  `dart run tool/export_cards.dart`. Re-export when the field guide changes.
