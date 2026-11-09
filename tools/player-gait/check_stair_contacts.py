#!/usr/bin/env python3
"""Read-only contact-order audit of actual production terrain JSONL observations.

Example: python3 tools/player-gait/check_stair_contacts.py --world .runtime/world-map.json \
    --run artifacts/godot/nala-production-terrain-... --output /tmp/contact-order.json
Exit 0: selected completed cases verified; 1: contradiction/rejected run; 2: incomplete evidence.
This does not check mesh clearance, limb reach, timing, artwork, or natural walking.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

LEVEL_HEIGHT = 48.0
HEIGHT_EPS = 0.001  # Godot's serialized Vector3 strings round coordinates.
SIDES = ("left", "right")


def vector(value):
    if isinstance(value, str):
        value = value.strip().strip("()").split(",")
    result = tuple(float(v) for v in value)
    if len(result) not in (2, 3) or not all(math.isfinite(v) for v in result):
        raise ValueError("Expected a finite Godot Vector2/Vector3 or numeric array")
    return result


def case_key(label):
    key = label.split(" ", 1)[0]
    parts = key.split("/")
    if len(parts) != 3 or any(v not in ("true", "false") for v in parts[1:]):
        raise ValueError("Unknown terrain case: " + label)
    return key, parts[0], parts[1] == "true", parts[2] == "true"


def profile_definitions(world):
    hub = world["landMaps"]["hub"]
    levels = {t["id"]: t["elevation"] * LEVEL_HEIGHT for t in hub["terraces"]}
    profiles = {}
    for stair in hub["stairs"]:
        profile = dict(stair)
        profile["startHeight"] = levels[stair["from"]]
        profile["endHeight"] = levels[stair["to"]]
        if profile["type"] == "stairs" and int(profile["steps"]) <= 0:
            raise ValueError("Staircase has no treads")
        profiles[profile["id"]] = profile
    return profiles


def expected_heights(profile, reverse):
    start, end = profile["startHeight"], profile["endHeight"]
    if reverse:
        start, end = end, start
    if profile["type"] != "stairs":
        return start, end, []
    count = int(profile["steps"])
    return start, end, [start + (end - start) * i / count for i in range(1, count + 1)]


def close(a, b):
    return abs(a - b) <= HEIGHT_EPS


def audit_case(key, records, profile, completed):
    _, _, reverse, _ = case_key(key)
    start, end, expected = expected_heights(profile, reverse)
    errors, insufficient, events = [], [], []
    previous = None
    previous_frame = None
    last_side = None
    next_tread = 0
    for record in records:
        frame = record["physicsFrame"]
        if previous_frame is not None and frame <= previous_frame:
            errors.append({"kind": "non_monotonic_frame", "frame": frame})
        previous_frame = frame
        contacts = record["pose"]["contacts"]
        counter = int(contacts["contacts"])
        feet = contacts["feet"]
        if previous is None:
            if counter != 0:
                insufficient.append({"kind": "initial_contacts_unobserved", "frame": frame, "counter": counter})
            previous = contacts
            continue
        candidates = []
        for side in SIDES:
            foot, old = feet[side], previous["feet"][side]
            # landingHeight/toWorld describe a future target, not a landed foot.
            if foot["grounded"] and (not old["grounded"] or vector(foot["plant"]) != vector(old["plant"])):
                candidates.append(side)
        delta = counter - int(previous["contacts"])
        if delta < 0:
            errors.append({"kind": "counter_reset_within_case", "frame": frame})
        if delta != len(candidates) or len(candidates) > 1:
            insufficient.append({"kind": "unobservable_contact_order", "frame": frame,
                                 "counterDelta": delta, "observedSides": candidates})
        if len(candidates) == 1 and delta == 1:
            side = candidates[0]
            foot = feet[side]
            height = vector(foot["plant"])[2]
            event = {"frame": frame, "side": side, "height": height,
                     "plant": list(vector(foot["plant"])), "phase": record["case"].partition(" ")[2]}
            events.append(event)
            if side == last_side:
                errors.append({"kind": "successive_same_side", **event})
            last_side = side
            if expected:
                current = start if next_tread == 0 else expected[next_tread - 1]
                if close(height, current):
                    event["role"] = "approach" if next_tread == 0 else "same_level"
                elif next_tread < len(expected) and close(height, expected[next_tread]):
                    event["role"] = "next_tread"
                    next_tread += 1
                else:
                    errors.append({"kind": "skipped_or_out_of_order_tread", "expectedNext":
                                   expected[next_tread] if next_tread < len(expected) else end, **event})
            elif height < min(start, end) - HEIGHT_EPS or height > max(start, end) + HEIGHT_EPS:
                errors.append({"kind": "ramp_contact_outside_height_range", **event})
        previous = contacts
    if profile["type"] != "stairs" and not events:
        insufficient.append({"kind": "no_observed_ramp_contacts"})
    missing = expected[next_tread:]
    if not records:
        insufficient.append({"kind": "no_observations"})
    if completed and missing:
        errors.append({"kind": "completed_route_missing_treads", "missing": missing})
    if not completed:
        insufficient.append({"kind": "route_not_declared_completed"})
    return {"case": key, "type": profile["type"], "expectedTreads": expected,
            "startHeight": start, "endHeight": end, "events": events,
            "missingTreads": missing, "completedMetadata": completed, "errors": errors,
            "insufficient": insufficient, "status": "fail" if errors else "incomplete" if insufficient else "pass",
            "scope": "discrete tread order" if expected else "continuous ramp height range and contact alternation; no discrete treads"}


def completed_metadata(entry):
    return all(entry.get(field) is True for field in
               ("entered", "crossed", "stopPauseRestart", "noRootPlacementAfterDeclaredSetup"))


def audit_run(world_bytes, run):
    world = json.loads(world_bytes)
    profiles = profile_definitions(world)
    source = json.loads((run / "source.json").read_text())
    sha = hashlib.sha256(world_bytes).hexdigest()
    provenance_errors = []
    if source.get("fixtureWorldSha256") != sha:
        provenance_errors.append("WORLD hash differs from source.json; no contact-order acceptance")
    metadata = []
    if (run / "terrain-cases.json").exists():
        metadata = json.loads((run / "terrain-cases.json").read_text())
    completed = {}
    for entry in metadata:
        key = case_key(entry["case"])[0]
        if key in completed:
            provenance_errors.append("Duplicate completed case metadata: " + key)
        completed[key] = completed_metadata(entry)
    grouped = {}
    with (run / "samples.jsonl").open() as stream:
        for line_number, line in enumerate(stream, 1):
            if not line.strip():
                continue
            try:
                record = json.loads(line)
                key, profile_id, _, _ = case_key(record["case"])
                if profile_id not in profiles:
                    raise ValueError("Unknown authored profile " + profile_id)
                grouped.setdefault(key, []).append(record)
            except (ValueError, KeyError) as error:
                raise ValueError(f"samples.jsonl:{line_number}: {error}") from error
    cases = []
    for key in sorted(set(grouped) | set(completed)):
        profile = profiles[case_key(key)[1]]
        cases.append(audit_case(key, grouped.get(key, []), profile, completed.get(key, False)))
    final = None
    if (run / "terrain-results.json").exists():
        final = json.loads((run / "terrain-results.json").read_text())
        if final.get("cases") != metadata:
            provenance_errors.append("Final cases differ from incrementally persisted terrain-cases.json")
    expected_matrix = {f"{p}/{str(reverse).lower()}/{str(reduced).lower()}"
                       for p in profiles for reverse in (False, True) for reduced in (False, True)}
    observed = {c["case"] for c in cases if c["status"] == "pass"}
    rejected = None
    if (run / "rejected.json").exists():
        rejected = json.loads((run / "rejected.json").read_text()).get("message", "rejected.json present")
    failed = bool(provenance_errors or rejected or any(c["status"] == "fail" for c in cases))
    incomplete = not cases or any(c["status"] == "incomplete" for c in cases) or final is None
    complete16 = (not failed and not incomplete and len(expected_matrix) == 16 and observed == expected_matrix
                  and final.get("complete16Cases") is True and len(metadata) == 16)
    return {"run": str(run), "worldSha256": sha, "recordedWorldSha256": source.get("fixtureWorldSha256"),
            "sourceFiles": source.get("files", {}), "status": "fail" if failed else "incomplete" if incomplete else "pass_selected_cases",
            "complete16CasesVerified": complete16, "missingMatrixCases": sorted(expected_matrix - observed),
            "provenanceErrors": provenance_errors, "originalRejection": rejected, "cases": cases,
            "limits": ["Observed landed plant heights only; no mesh/pixel/reach/clearance or natural-walk acceptance",
                       "Simultaneous contacts/counter gaps do not establish their internal order",
                       "Ramp cases verify range/alternation and completion metadata, not discrete tread order",
                       "Initial idle is absent from JSONL; nonzero first counter is incomplete evidence",
                       "Each run audited separately; different source hashes are never combined"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        result = audit_run(args.world.read_bytes(), args.run)
        rendered = json.dumps(result, indent=2) + "\n"
        if args.output:
            with args.output.open("x") as stream:  # Existing evidence must not be replaced.
                stream.write(rendered)
        else:
            print(rendered, end="")
        return 1 if result["status"] == "fail" else 2 if result["status"] == "incomplete" else 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(2, f"Contact audit input error: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
