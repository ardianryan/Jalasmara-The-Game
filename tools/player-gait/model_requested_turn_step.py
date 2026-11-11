#!/usr/bin/env python3
"""Compare the captured reversal's next unfired swing using its existing short-step rule."""
import argparse
import json
import math
from pathlib import Path

from model_ramp_sole import vector


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--world", type=Path, required=True)
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    run = json.loads((args.run / "rejected.json").read_text())
    rows = [json.loads(line) for line in (args.run / "samples.jsonl").read_text().splitlines()]
    label = run["recentTrace"][-1]["case"].split(" ")[0]
    rows = [row for row in rows if row["case"].split(" ")[0] == label]
    previous, changed = next((a, b) for a, b in zip(rows, rows[1:])
                             if a["pose"]["contacts"]["swingSide"] == "left"
                             and b["pose"]["contacts"]["swingSide"] == "right")
    assert changed["pose"]["direction"] != changed["pose"]["desiredDirection"]
    before, after = previous["pose"]["contacts"], changed["pose"]["contacts"]
    assert before["acceptedDistance"] < before["landingDistance"] < after["acceptedDistance"]
    foot = after["feet"]["right"]
    config = json.loads((args.run / "source.json").read_text())["physicalContract"]
    old_distance, lead = config["steadyDistance"], config["landingLead"]
    start, destination = vector(foot["fromWorld"]), vector(foot["toWorld"])
    assert abs(start[0] - destination[0]) < .001
    base_y = destination[1] + old_distance + lead
    projection = -(start[1] - base_y)
    minimum = max(config["startDistance"], math.ceil(1.5 * (lead - projection) / 2.5))
    target_y = base_y - minimum - lead
    hub = json.loads(args.world.read_text())["landMaps"]["hub"]
    ramp = next(row for row in hub["stairs"] if row["id"] == "dock_gangway")
    levels = {row["id"]: row["elevation"] * 48 for row in hub["terraces"]}
    low, high = levels[ramp["from"]], levels[ramp["to"]]
    tilt = math.radians(55)
    y0, y1 = [-ramp["path"][i][1] / math.cos(tilt) - levels[ramp[key]] * math.tan(tilt)
              for i, key in enumerate(["from", "to"])]
    z = low + (high - low) * min(1, max(0, (target_y - y0) / (y1 - y0)))
    target_logical_y = -(target_y + z * math.tan(tilt)) * math.cos(tilt)
    span = abs(target_y - start[1])
    slope = abs((high - low) / (y1 - y0))
    numerator = 1.5 * math.hypot(span, slope * span) + 3 * math.pi
    duration = max(minimum, math.ceil(numerator / 4.9 * 4) / 4)
    assert z > destination[2] and span < abs(destination[1] - start[1])
    assert numerator / duration <= 4.9
    result = {"scope": "One captured straight dock reversal, existing short-step rule before its next unfired swing only",
              "source": str(args.run), "requestAlreadyPendingBeforeNewSwing": True,
              "actualBody": changed["pose"]["direction"], "actualDesired": changed["pose"]["desiredDirection"],
              "trailingProjection": projection, "minimumRequestedDistance": minimum,
              "oldDuration": old_distance, "oldTargetWorld": destination,
              "proposedTargetLogicalY": target_logical_y, "proposedTargetWorld": [destination[0], target_y, z],
              "proposedGeometryDuration": duration, "baseCurveBoundOnly": numerator / duration,
              "notProven": ["original-mask landing fit", "support-envelope trajectory and ankle rate",
                            "body transfer and leg reach", "live facing recovery or full gait"]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print("REQUESTED TURN MODEL: pending actual view mismatch precedes new swing; existing short policy selects nearer real ramp target")


if __name__ == "__main__":
    main()
