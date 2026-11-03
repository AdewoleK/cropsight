# CropSight Plant Health Watch

The server CropSight phones report to, and the dashboard plant-health officers
sign in to and review outbreak alerts on.

**Live:** https://cropsight-watch.onrender.com (Render, Frankfurt), storing data
in Supabase Postgres (London) in a private `watch` schema with row-level
security on. Officer accounts are Supabase Auth users, invite-only.

## Run locally

```bash
cd server
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python app.py               # http://localhost:8787
.venv/bin/python simulate.py          # load labelled demo data (optional)
.venv/bin/python -m unittest discover -s tests
```

Settings come from environment variables, or `server/.env` locally (never
committed):

| Variable | What it does |
|---|---|
| `DATABASE_URL` | Supabase Postgres (Session pooler URI). Unset: a local SQLite file. |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Officer sign-in. Unset: the dashboard is open (local development only). |
| `ALERT_WEBHOOK` | Optional URL each new alert is POSTed to (e.g. an SMS gateway). |

`TEST_DATABASE_URL=… python -m unittest tests.test_store` runs the storage
tests against Postgres, each in a throwaway schema.

## Officers

Invite officers in Supabase (Authentication → Users → Send invitation). The
email links to the dashboard, where they set a password. "Forgot password"
on the sign-in screen sends a reset link. Reviews record who made them.

Phones need no sign-in to report (`POST /api/reports`); everything else under
`/api/` except `/api/health` and `/api/config` requires an officer session.

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

This is a pilot. HTTPS, officer sign-in and a managed database are in place.
Still needed: rate limiting on `/api/reports`, a paid Supabase plan (free
projects pause after a week idle and have limited backups), a paid Render
instance (free ones sleep after 15 minutes idle), and a data-protection review
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
