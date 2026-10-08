"""Checks a dump from dump_chunks.gd against the generator's acceptance targets (ADR 0011).

Usage: python3 tools/generation/analyze.py <dump.json>
Exits non-zero when a target fails.
"""
import json
import math
import statistics as st
import sys
from collections import Counter, defaultdict

LETHAL_ENVELOPES = {  # relative to the hazard socket, y negative up (FieldChunkDecorator.lethal_envelope)
    "FALLING_ROCK": (-0.3, -0.2, 0.6, 2.2),
    "PENDULUM_LOG": (-0.7, -0.2, 1.4, 0.55),
    "SPIKE_CLUSTER": (-0.45, -0.45, 0.9, 0.9),
}
STATIC_REACH = 0.96
# band -> (longest-move p95 limit, minimum hold span)
TARGETS = {"EASY": (1.30, 9.0), "BASELINE": (1.70, 9.0), "CHALLENGE": (2.10, 9.0)}


def edge_gap(a, b):
    gx = max(0.0, abs(a["x"] - b["x"]) - (a["w"] + b["w"]) / 2)
    gy = max(0.0, abs(a["y"] - b["y"]) - (a["h"] + b["h"]) / 2)
    return math.hypot(gx, gy)


def main(path):
    data = json.load(open(path))
    band = defaultdict(lambda: defaultdict(list))
    kinds = Counter()
    coins_in_lethal = 0
    force_off = force_total = 0
    for run in data["runs"]:
        for chunk in run["chunks"]:
            stats = band[chunk["band"]]
            holds = {h["id"]: h for h in chunk["holds"]}
            route = chunk["safe_order"]
            moves = [math.dist((holds[a]["x"], holds[a]["y"]), (holds[b]["x"], holds[b]["y"])) for a, b in zip(route, route[1:])]
            swings = [edge_gap(holds[a], holds[b]) > STATIC_REACH for a, b in zip(route, route[1:])]
            if moves:
                stats["longest"].append(max(moves))
                stats["swing"].append(sum(swings) / len(swings))
            xs = [h["x"] for h in chunk["holds"]]
            stats["span"].append(max(xs) - min(xs))
            stats["holds"].append(len(chunk["holds"]))
            stats["ms"].append(chunk["ms"])
            for hazard in chunk["hazards"]:
                kinds[hazard["kind"]] += 1
                if hazard["kind"] in LETHAL_ENVELOPES:
                    ex, ey, ew, eh = LETHAL_ENVELOPES[hazard["kind"]]
                    for coin in chunk["pickups"]:
                        if hazard["x"] + ex <= coin["x"] <= hazard["x"] + ex + ew and hazard["y"] + ey <= coin["y"] <= hazard["y"] + ey + eh:
                            coins_in_lethal += 1
                else:
                    force_total += 1
                    force_off += not any(math.dist((hazard["x"], hazard["y"]), (holds[i]["x"], holds[i]["y"])) < 0.8 for i in route)

    pct = lambda values, q: sorted(values)[min(len(values) - 1, int(len(values) * q))]
    failures = []
    print("chunks:", sum(len(r["chunks"]) for r in data["runs"]))
    for name in ["EASY", "BASELINE", "CHALLENGE"]:
        stats = band[name]
        if not stats["longest"]:
            continue
        p95 = pct(stats["longest"], 0.95)
        span = st.median(stats["span"])
        print(f"{name:9} longest move median {st.median(stats['longest']):.2f} p95 {p95:.2f} | swing {100 * st.mean(stats['swing']):.0f}% | "
              f"span {span:.1f} m | holds {st.median(stats['holds']):.0f} | ms p50 {st.median(stats['ms']):.1f} p95 {pct(stats['ms'], 0.95):.1f}")
        limit, min_span = TARGETS[name]
        if p95 > limit + 1e-6:
            failures.append(f"{name} longest move p95 {p95:.2f} > {limit}")
        if span < min_span:
            failures.append(f"{name} hold span {span:.1f} < {min_span}")
    print("force/nuisance hazards off the easiest route: %.0f%%" % (100 * force_off / max(1, force_total)))
    print("coins inside a lethal envelope:", coins_in_lethal)
    print("hazard kinds:", dict(kinds.most_common()))
    if coins_in_lethal:
        failures.append("coins inside lethal envelopes")
    if force_off < 0.3 * force_total:
        failures.append("fewer than 30% of force hazards off the easiest route")
    for failure in failures:
        print("FAIL:", failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
