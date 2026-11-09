#!/usr/bin/env python3
"""Audit actual body and original shoe views against desired artwork in gait JSONL."""
import argparse
import json
from pathlib import Path


def audit(rows, expected_cases, rejections=None):
    cases = {}
    for row in rows:
        label = row["case"].split(" ", 1)[0]
        pose = row["pose"]
        artwork = pose.get("desiredDirection")
        requested = row.get("source", {}).get("requestedDirection")
        desired = requested or artwork
        body = pose.get("direction")
        feet = pose.get("contacts", {}).get("feet", {})
        if label not in cases:
            cases[label] = {"observations": 0, "desiredChanges": 0, "directions": [], "artworkDirections": [],
                            "requestedDirectionObservations": 0, "incompleteObservations": 0,
                            "body": {}, "left": {}, "right": {}, "lastDesired": None, "priorAccepted": 0.0}
        case = cases[label]
        case["observations"] += 1
        case["requestedDirectionObservations"] += int(bool(requested))
        if artwork and artwork not in case["artworkDirections"]:
            case["artworkDirections"].append(artwork)
        if desired is None or body is None or not all("footDirection" in feet.get(side, {}) for side in ["left", "right"]):
            case["incompleteObservations"] += 1
            continue
        if desired not in case["directions"]:
            case["directions"].append(desired)
        changed = case["lastDesired"] is not None and desired != case["lastDesired"]
        case["desiredChanges"] += int(changed)
        accepted = float(pose["contacts"].get("acceptedDistance", 0))
        distance = max(0, accepted - case["priorAccepted"])
        seconds = 0.0 if bool(row.get("fixtureInitial", False)) else float(row.get("physicsDelta", 0))
        paused = bool(row.get("source", {}).get("poseFrozen", False)) or "paused" in row["case"]
        if paused:
            seconds = 0.0
            distance = 0.0
        for component, actual in [("body", body), ("left", feet["left"]["footDirection"]), ("right", feet["right"]["footDirection"])]:
            state = case[component]
            if not state:
                state.update(maxHeldSeconds=0.0, maxHeldAcceptedDistance=0.0, heldSeconds=0.0,
                             heldAcceptedDistance=0.0, freeFootObservations=0, recoveries=0, wasHeld=False)
            held = actual != desired
            if held:
                state["heldSeconds"] += seconds
                state["heldAcceptedDistance"] += distance
            else:
                state["recoveries"] += int(state["wasHeld"] and not changed)
                state["heldSeconds"] = 0.0
                state["heldAcceptedDistance"] = 0.0
            state["maxHeldSeconds"] = max(state["maxHeldSeconds"], state["heldSeconds"])
            state["maxHeldAcceptedDistance"] = max(state["maxHeldAcceptedDistance"], state["heldAcceptedDistance"])
            if component != "body" and not paused and not bool(feet[component].get("grounded", True)):
                state["freeFootObservations"] += 1
            state.update(wasHeld=held, terminalActual=actual, terminalDesired=desired, terminalMatches=not held)
        case["lastDesired"] = desired
        case["priorAccepted"] = accepted
    missing = max(0, expected_cases - len(cases))
    mismatches = []
    insufficient = []
    for label, case in cases.items():
        if case["incompleteObservations"] or any(not case[component] for component in ["body", "left", "right"]):
            insufficient.append(label)
        for component in ["body", "left", "right"]:
            state = case[component]
            if state and not state["terminalMatches"]:
                mismatches.append({"case": label, "component": component, "actual": state["terminalActual"],
                                   "desired": state["terminalDesired"], "freeFootObservations": state["freeFootObservations"]})
            state.pop("wasHeld", None)
        case.pop("lastDesired")
        case.pop("priorAccepted")
    complete = len(cases) == expected_cases and not insufficient
    return {"scope": "Actual recorded final source views and hold intervals only; no naturalness or missing-case inference",
            "desiredSource": "requestedDirection when recorded; intermediate artwork target only for older observations",
            "expectedCases": expected_cases, "observedCases": len(cases), "missingCases": missing,
            "completeCaseSet": complete, "incompleteObservationCases": insufficient,
            "terminalMismatches": mismatches, "originalRejections": rejections or [],
            "terminalRecoveryAccepted": complete and not mismatches and not rejections,
            "cases": cases}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=Path, action="append", required=True)
    parser.add_argument("--expected-cases", type=int, default=32)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    rows = []
    rejections = []
    for directory in args.run:
        rows.extend(json.loads(line) for line in (directory / "samples.jsonl").read_text().splitlines() if line.strip())
        rejection = directory / "rejected.json"
        if rejection.exists():
            rejections.append({"run": str(directory), "message": json.loads(rejection.read_text())["message"]})
    result = audit(rows, args.expected_cases, rejections)
    result["runs"] = [str(path) for path in args.run]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: value for key, value in result.items() if key != "cases"}, indent=2))


if __name__ == "__main__":
    main()
