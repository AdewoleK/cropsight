"""Loads SIMULATED reports so the dashboard can be demonstrated before real
farmers are reporting. Every row it writes is flagged simulated=1, and the
dashboard labels it as such. Real phone reports are never touched.

    python3 simulate.py            # replace any previous simulated data
    python3 simulate.py --clear    # remove simulated data only

Background: ~120 days of everyday reports across 20 states, spread thinly
enough that nothing alerts. On top of that, four scenarios:
  1. Tuta absoluta appears in Ikara (Kaduna), with nearby LGAs following.
  2. Fall armyworm surges in Dawakin Tofa (Kano), where it is usually low.
  3. Several farmers in Jos South (Plateau) get "unclear match".
  4. Two farmers in Ogbomosho North (Oyo) report cassava brown streak:
     below the alert threshold, so it shows as "watch" only.
"""

import os
import random
import sys
import uuid
from datetime import timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from surveillance.config import database_target  # noqa: E402
from surveillance.store import Surveillance, utcnow  # noqa: E402

HERE = Path(__file__).resolve().parent
rng = random.Random(2016)

ENDEMIC = {
    "north": (["Kano", "Kaduna", "Katsina", "Jigawa", "Sokoto", "Kebbi", "Zamfara", "Bauchi",
               "Gombe"],
              ["fall_armyworm", "maize_streak_virus", "striga", "millet_downy_mildew",
               "sorghum_anthracnose", "cowpea_pod_borer", "groundnut_rosette", "onion_thrips",
               "tomato_early_blight", "groundnut_leaf_spot"]),
    "middle": (["Plateau", "Niger", "Benue", "Nasarawa", "Federal Capital Territory", "Kwara"],
               ["yam_anthracnose", "cassava_mosaic", "rice_blast", "potato_late_blight",
                "maize_leaf_blight", "soybean_rust", "yam_mosaic_virus"]),
    "south": (["Oyo", "Ogun", "Ondo", "Enugu", "Cross River"],
              ["cassava_mosaic", "cassava_mealybug", "cocoa_black_pod",
               "banana_black_sigatoka", "maize_leaf_blight", "cassava_bacterial_blight"]),
}

# Kept out of the background so the scenarios below are the only source.
SCENARIO_CARDS = {"tomato_tuta_absoluta", "cassava_brown_streak"}


def lga_code(w, name, state):
    for code, lga in w.lgas.items():
        if lga["name"] == name and lga["state"] == state:
            return code
    raise SystemExit(f"no LGA {name!r} in {state!r}")


def lgas_in(w, state):
    return [c for c, lga in w.lgas.items() if lga["state"] == state]


def result(farmer, days_ago, lga, card=None, source=None, confidence=None, unclear=False):
    now = utcnow()
    source = source or rng.choice(["photo", "photo", "lite"])
    if source == "photo" and confidence is None:
        confidence = rng.choice(["high", "medium", "medium", "low"])
    when = now - timedelta(days=days_ago, hours=rng.uniform(0, 10))
    return {
        "id": uuid.uuid4().hex,
        "anonymous_id": farmer,
        "timestamp": min(when, now).isoformat(),
        "source": source,
        "confidence": confidence,
        "unclear": unclear,
        "lga_pcode": lga,
        "cited_cards": [] if unclear else [{"id": card, "score": round(rng.uniform(0.55, 0.85), 3)}],
    }


def farmer():
    return "sim-" + uuid.uuid4().hex[:12]


def background(w):
    out = []
    for states, cards in ENDEMIC.values():
        for state in states:
            codes = lgas_in(w, state)
            for _ in range(rng.randint(14, 26)):
                out.append(result(farmer(), rng.uniform(0, 120), rng.choice(codes),
                                  rng.choice(cards)))
    return out


def scenarios(w):
    out = []
    ikara = lga_code(w, "Ikara", "Kaduna")
    for d in (9, 7, 6, 4, 3, 1):
        out.append(result(farmer(), d, ikara, "tomato_tuta_absoluta", source="lite"))
    for name in ("Markafi", "Kubau"):
        for d in (3, 1):
            out.append(result(farmer(), d, lga_code(w, name, "Kaduna"), "tomato_tuta_absoluta",
                              source="photo", confidence="high"))

    tofa = lga_code(w, "Dawakin Tofa", "Kano")
    for d in (100, 80, 62, 45, 30):
        out.append(result(farmer(), d, tofa, "fall_armyworm", source="lite"))
    for d in (12, 9, 8, 6, 4, 3, 2):
        out.append(result(farmer(), d, tofa, "fall_armyworm", source="photo", confidence="high"))

    jos = lga_code(w, "Jos South", "Plateau")
    for d in (8, 5, 3, 2):
        out.append(result(farmer(), d, jos, source="photo", confidence="low", unclear=True))

    ogbo = lga_code(w, "Ogbomosho North", "Oyo")
    for d in (5, 2):
        out.append(result(farmer(), d, ogbo, "cassava_brown_streak", source="lite"))
    return out


def main():
    w = Surveillance(database_target())
    with w.db.transaction():
        # Remove only alerts that rest entirely on demo data; alerts with any
        # real phone report keep their history and officers' notes.
        demo = [r["id"] for r in w.db.execute("SELECT * FROM alerts").fetchall()
                if w.provenance(r) == "simulated"]
        w.db.executemany("DELETE FROM alerts WHERE id=?", [(i,) for i in demo])
        w.db.execute("DELETE FROM reports WHERE simulated=1")
    if "--clear" in sys.argv:
        w.run_detection()
        print("Simulated data removed.")
        return
    bg = [r for r in background(w) if r["cited_cards"][0]["id"] not in SCENARIO_CARDS]
    stats = w.ingest(bg + scenarios(w), simulated=True)
    print(f"Simulated reports loaded: {stats['accepted']} (rejected {len(stats['rejected'])})")
    for a in w.alerts("open"):
        print(f"  [{a['severity']}] {a['kind']}: {a['explanation']}")
    print(f"  watch: {len(w.watch)} LGA/problem pairs")


if __name__ == "__main__":
    main()
