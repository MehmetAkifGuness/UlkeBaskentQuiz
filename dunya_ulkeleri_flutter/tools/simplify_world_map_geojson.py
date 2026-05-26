import argparse
import json
import math
from pathlib import Path


def perpendicular_distance(point, start, end):
    (x, y) = point
    (x1, y1) = start
    (x2, y2) = end
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return math.hypot(x - x1, y - y1)
    t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)
    if t < 0:
        px, py = x1, y1
    elif t > 1:
        px, py = x2, y2
    else:
        px, py = x1 + t * dx, y1 + t * dy
    return math.hypot(x - px, y - py)


def rdp_mask(points, epsilon):
    if len(points) <= 2:
        return [True] * len(points)

    stack = [(0, len(points) - 1)]
    keep = [False] * len(points)
    keep[0] = True
    keep[-1] = True

    while stack:
        start_idx, end_idx = stack.pop()
        start = points[start_idx]
        end = points[end_idx]

        max_dist = -1.0
        max_index = None
        for i in range(start_idx + 1, end_idx):
            d = perpendicular_distance(points[i], start, end)
            if d > max_dist:
                max_dist = d
                max_index = i

        if max_index is not None and max_dist > epsilon:
            keep[max_index] = True
            stack.append((start_idx, max_index))
            stack.append((max_index, end_idx))

    return keep


def rdp(points, epsilon):
    keep = rdp_mask(points, epsilon)
    return [p for i, p in enumerate(points) if keep[i]]


def simplify_ring(ring, epsilon):
    if not ring or len(ring) < 4:
        return ring

    first = ring[0]
    last = ring[-1]
    if first[0] == last[0] and first[1] == last[1]:
        core = ring[:-1]
    else:
        core = ring

    keep = rdp_mask([(p[0], p[1]) for p in core], epsilon)
    out = [p for p, k in zip(core, keep) if k]
    if len(out) < 3:
        return ring

    out.append(out[0])
    return out


def simplify_geometry(geometry, epsilon):
    gtype = geometry.get("type")
    coords = geometry.get("coordinates")
    if coords is None:
        return geometry

    if gtype == "Polygon":
        return {**geometry, "coordinates": [simplify_ring(r, epsilon) for r in coords]}

    if gtype == "MultiPolygon":
        new_polys = []
        for poly in coords:
            new_polys.append([simplify_ring(r, epsilon) for r in poly])
        return {**geometry, "coordinates": new_polys}

    return geometry


def round_geometry_coordinates(geometry, decimals):
    coords = geometry.get("coordinates")
    if coords is None:
        return geometry

    def round_any(x):
        if isinstance(x, list):
            return [round_any(v) for v in x]
        if isinstance(x, float):
            return round(x, decimals)
        return x

    return {**geometry, "coordinates": round_any(coords)}


def main():
    parser = argparse.ArgumentParser(
        description="GeoJSON world map'i performans için sadeleştirir (RDP)."
    )
    parser.add_argument(
        "--input",
        default="assets/maps/world_map.json",
        help="Girdi GeoJSON yolu (FeatureCollection).",
    )
    parser.add_argument(
        "--output",
        default="assets/maps/world_map_simplified.json",
        help="Çıktı GeoJSON yolu.",
    )
    parser.add_argument(
        "--tolerance",
        type=float,
        default=0.02,
        help="Sadeleştirme toleransı (derece). Örn: 0.02 ~ birkaç km.",
    )
    parser.add_argument(
        "--round",
        type=int,
        default=5,
        help="Koordinat yuvarlama basamağı (dosya boyutunu azaltır).",
    )
    args = parser.parse_args()

    src = Path(args.input)
    dst = Path(args.output)

    data = json.loads(src.read_text(encoding="utf-8"))
    features = data.get("features", [])

    new_features = []
    for feat in features:
        geom = feat.get("geometry") or {}
        if isinstance(geom, dict):
            new_geom = simplify_geometry(geom, args.tolerance)
            if args.round is not None and args.round >= 0:
                new_geom = round_geometry_coordinates(new_geom, args.round)
            new_feat = {**feat, "geometry": new_geom}
            new_features.append(new_feat)
        else:
            new_features.append(feat)

    data["features"] = new_features

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    print(f"Wrote: {dst} ({dst.stat().st_size} bytes)")


if __name__ == "__main__":
    main()

