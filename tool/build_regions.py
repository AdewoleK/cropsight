"""Builds CropSight's Nigeria region data from OCHA's COD-AB boundaries.

Source: "Nigeria - Subnational Administrative Boundaries" on HDX
(https://data.humdata.org/dataset/cod-ab-nga), CC BY-IGO. Download
nga_admin_boundaries.geojson.zip, unzip it, and pass the folder:

    python3 tool/build_regions.py /path/to/unzipped

Writes:
  assets/regions/nigeria_lgas.json  - states and their LGAs, for the app's picker
  server/data/regions.json          - every LGA's name, state, centre and neighbours
  server/data/states.geojson        - simplified state outlines for the dashboard map
  server/data/lgas.geojson          - simplified LGA outlines for the dashboard map
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_NOTE = (
    "OCHA COD-AB Nigeria subnational boundaries (HDX, CC BY-IGO), "
    "https://data.humdata.org/dataset/cod-ab-nga"
)


def rings(geometry):
    if geometry["type"] == "Polygon":
        return [geometry["coordinates"]]
    return geometry["coordinates"]


def simplify(points, tolerance):
    """Douglas-Peucker on one ring; keeps first and last points."""
    if len(points) < 4:
        return points
    if points[0][:2] == points[-1][:2]:
        # A closed ring's start and end coincide, which would make every point
        # measure zero from the "segment" between them. Split at the farthest
        # point and simplify the two halves.
        x0, y0 = points[0][:2]
        far = max(range(len(points)),
                  key=lambda i: (points[i][0] - x0) ** 2 + (points[i][1] - y0) ** 2)
        return simplify(points[:far + 1], tolerance)[:-1] + simplify(points[far:], tolerance)
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        start, end = stack.pop()
        (x1, y1), (x2, y2) = points[start][:2], points[end][:2]
        dx, dy = x2 - x1, y2 - y1
        norm = (dx * dx + dy * dy) ** 0.5 or 1e-12
        best, index = 0.0, None
        for i in range(start + 1, end):
            px, py = points[i][:2]
            dist = abs(dy * px - dx * py + x2 * y1 - y2 * x1) / norm
            if dist > best:
                best, index = dist, i
        if index is not None and best > tolerance:
            keep[index] = True
            stack += [(start, index), (index, end)]
    return [[round(p[0], 4), round(p[1], 4)] for p, k in zip(points, keep) if k]


def simplified_geometry(geometry, tolerance):
    polygons = []
    for polygon in rings(geometry):
        out = [simplify(ring, tolerance) for ring in polygon]
        if len(out[0]) >= 4:
            polygons.append(out)
    return {"type": "MultiPolygon", "coordinates": polygons}


def neighbours(features):
    """LGAs that share boundary vertices are neighbours. COD-AB boundaries are
    topologically clean, so shared edges share exact vertices."""
    owners = defaultdict(set)
    for f in features:
        code = f["properties"]["adm2_pcode"]
        for polygon in rings(f["geometry"]):
            for ring in polygon:
                for x, y, *_ in ring:
                    owners[(round(x, 5), round(y, 5))].add(code)
    shared = defaultdict(lambda: defaultdict(int))
    for codes in owners.values():
        for a in codes:
            for b in codes:
                if a != b:
                    shared[a][b] += 1
    # Two or more shared vertices means a shared edge, not a single corner.
    return {a: sorted(b for b, n in counts.items() if n >= 2) for a, counts in shared.items()}


def main(src):
    src = Path(src)
    admin1 = json.loads((src / "nga_admin1.geojson").read_text())["features"]
    admin2 = json.loads((src / "nga_admin2.geojson").read_text())["features"]

    states = sorted(
        ({"pcode": f["properties"]["adm1_pcode"], "name": f["properties"]["adm1_name"]} for f in admin1),
        key=lambda s: s["name"],
    )
    lgas_by_state = defaultdict(list)
    for f in admin2:
        p = f["properties"]
        lgas_by_state[p["adm1_pcode"]].append({"pcode": p["adm2_pcode"], "name": p["adm2_name"]})

    app_regions = {
        "source": SOURCE_NOTE,
        "states": [
            {**s, "lgas": sorted(lgas_by_state[s["pcode"]], key=lambda l: l["name"])}
            for s in states
        ],
    }
    out = ROOT / "assets/regions/nigeria_lgas.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(app_regions, ensure_ascii=False, separators=(",", ":")))

    adjacency = neighbours(admin2)
    state_names = {s["pcode"]: s["name"] for s in states}
    server_regions = {
        "source": SOURCE_NOTE,
        "states": {s["pcode"]: s["name"] for s in states},
        "lgas": {
            f["properties"]["adm2_pcode"]: {
                "name": f["properties"]["adm2_name"],
                "state_pcode": f["properties"]["adm1_pcode"],
                "state": state_names[f["properties"]["adm1_pcode"]],
                "lat": round(f["properties"]["center_lat"], 4),
                "lon": round(f["properties"]["center_lon"], 4),
                "neighbours": adjacency.get(f["properties"]["adm2_pcode"], []),
            }
            for f in admin2
        },
    }
    data = ROOT / "server/data"
    data.mkdir(parents=True, exist_ok=True)
    (data / "regions.json").write_text(json.dumps(server_regions, ensure_ascii=False, indent=1))

    def collection(features, code_key, name_key, tolerance):
        return {
            "type": "FeatureCollection",
            "source": SOURCE_NOTE,
            "features": [
                {
                    "type": "Feature",
                    "properties": {"pcode": f["properties"][code_key], "name": f["properties"][name_key]},
                    "geometry": simplified_geometry(f["geometry"], tolerance),
                }
                for f in features
            ],
        }

    (data / "states.geojson").write_text(
        json.dumps(collection(admin1, "adm1_pcode", "adm1_name", 0.003), separators=(",", ":")))
    (data / "lgas.geojson").write_text(
        json.dumps(collection(admin2, "adm2_pcode", "adm2_name", 0.006), separators=(",", ":")))

    isolated = [c for c in server_regions["lgas"] if not server_regions["lgas"][c]["neighbours"]]
    print(f"{len(states)} states, {len(admin2)} LGAs, {len(isolated)} without neighbours")


if __name__ == "__main__":
    main(sys.argv[1])
