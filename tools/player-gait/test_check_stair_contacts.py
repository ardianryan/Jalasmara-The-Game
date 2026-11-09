import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from check_stair_contacts import audit_case, audit_run, expected_heights, profile_definitions, vector


WORLD = {"landMaps": {"hub": {
    "terraces": [{"id": "low", "elevation": 1}, {"id": "high", "elevation": 2}],
    "stairs": [{"id": "steps", "type": "stairs", "from": "low", "to": "high", "steps": 4,
                "path": [[0, 80], [0, 0]], "width": 120}]
}}}
PROFILE = profile_definitions(WORLD)["steps"]
KEY = "steps/false/false"


def observation(frame, counter, left=(True, 0, 48), right=(True, 1, 48), key=KEY):
    feet = {}
    for side, (grounded, x, height) in zip(("left", "right"), (left, right)):
        feet[side] = {"grounded": grounded, "plant": f"({x}, 0, {height})",
                      "sole": f"({x}, 0, {height})", "landingHeight": 999}
    return {"case": key + " travel", "physicsFrame": frame,
            "pose": {"contacts": {"contacts": counter, "feet": feet}}}


def contact_series(heights, key=KEY, sides=None):
    start = 96 if "/true/" in key else 48
    feet = {"left": (True, 0, start), "right": (True, 1, start)}
    records = [observation(1, 0, **feet, key=key)]
    for i, height in enumerate(heights):
        side = sides[i] if sides else ("left" if i % 2 == 0 else "right")
        feet[side] = (False, feet[side][1], feet[side][2])
        records.append(observation(2 * i + 2, i, **feet, key=key))
        feet[side] = (True, 10 + i, height)
        records.append(observation(2 * i + 3, i + 1, **feet, key=key))
    return records


class ContactOrderTests(unittest.TestCase):
    def test_authored_directional_treads(self):
        self.assertEqual(expected_heights(PROFILE, False), (48, 96, [60, 72, 84, 96]))
        self.assertEqual(expected_heights(PROFILE, True), (96, 48, [84, 72, 60, 48]))

    def test_ordered_ascent_with_approach_exit_and_stop_samples(self):
        samples = contact_series([48, 60, 72, 84, 96, 96])
        samples.insert(1, copy.deepcopy(samples[0]))
        samples[1]["physicsFrame"] = 1.5
        result = audit_case(KEY, samples, PROFILE, True)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(len(result["events"]), 6)

    def test_ordered_descent(self):
        key = "steps/true/false"
        self.assertEqual(audit_case(key, contact_series([84, 72, 60, 48], key), PROFILE, True)["status"], "pass")

    def test_skipped_first_tread_fails_even_on_rejected_partial(self):
        result = audit_case(KEY, contact_series([48, 72]), PROFILE, False)
        self.assertEqual(result["status"], "fail")
        self.assertIn("skipped_or_out_of_order_tread", [e["kind"] for e in result["errors"]])
        self.assertEqual(result["missingTreads"], [60, 72, 84, 96])

    def test_wrong_direction_fails(self):
        key = "steps/true/false"
        result = audit_case(key, contact_series([60, 72, 84, 96], key), PROFILE, True)
        self.assertEqual(result["status"], "fail")

    def test_successive_same_side_fails(self):
        result = audit_case(KEY, contact_series([60, 72, 84, 96], sides=["left"] * 4), PROFILE, True)
        self.assertIn("successive_same_side", [e["kind"] for e in result["errors"]])

    def test_repeated_grounded_sample_not_duplicate_landing(self):
        samples = contact_series([60, 72, 84, 96])
        sample = copy.deepcopy(samples[2]); sample["physicsFrame"] += 0.5
        samples.insert(3, sample)
        result = audit_case(KEY, samples, PROFILE, True)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(len(result["events"]), 4)

    def test_new_plant_detects_landing_without_observed_swing(self):
        samples = contact_series([60, 72, 84, 96])
        samples = [sample for i, sample in enumerate(samples) if i == 0 or i % 2 == 0]
        self.assertEqual(audit_case(KEY, samples, PROFILE, True)["status"], "pass")

    def test_counter_gap_and_simultaneous_feet_are_not_fabricated_order(self):
        samples = [observation(1, 0), observation(2, 2, (True, 3, 60), (True, 4, 72))]
        result = audit_case(KEY, samples, PROFILE, False)
        self.assertEqual(result["status"], "incomplete")
        self.assertEqual(result["events"], [])
        self.assertIn("unobservable_contact_order", [e["kind"] for e in result["insufficient"]])

    def test_initial_nonzero_counter_is_incomplete(self):
        samples = contact_series([60, 72, 84, 96])
        for sample in samples: sample["pose"]["contacts"]["contacts"] += 1
        self.assertEqual(audit_case(KEY, samples, PROFILE, True)["status"], "incomplete")

    def test_missing_treads_fail_completed_but_preserve_partial_prefix(self):
        self.assertEqual(audit_case(KEY, contact_series([60, 72]), PROFILE, True)["status"], "fail")
        result = audit_case(KEY, contact_series([60, 72]), PROFILE, False)
        self.assertEqual(result["status"], "incomplete")
        self.assertEqual(result["missingTreads"], [84, 96])

    def test_ramp_is_continuous_not_a_fake_single_tread(self):
        ramp = {**PROFILE, "type": "ramp", "steps": 1}
        result = audit_case(KEY, contact_series([55.3, 76.9, 96]), ramp, True)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["expectedTreads"], [])
        self.assertEqual(audit_case(KEY, [observation(1, 0)], ramp, True)["status"], "incomplete")
        self.assertEqual(audit_case(KEY, contact_series([100]), ramp, True)["status"], "fail")

    def test_full_matrix_requires_all_actual_observation_groups(self):
        world = copy.deepcopy(WORLD)
        stairs = world["landMaps"]["hub"]["stairs"]
        stairs[:] = [{**PROFILE, "id": "profile" + str(i), "from": "low", "to": "high",
                      "type": "ramp" if i == 0 else "stairs"} for i in range(4)]
        raw = json.dumps(world).encode()
        with tempfile.TemporaryDirectory() as folder:
            run = Path(folder)
            (run / "source.json").write_text(json.dumps({"fixtureWorldSha256": hashlib.sha256(raw).hexdigest()}))
            samples, metadata = [], []
            for profile in stairs:
                for reverse in (False, True):
                    for reduced in (False, True):
                        key = f"{profile['id']}/{str(reverse).lower()}/{str(reduced).lower()}"
                        heights = [84, 72, 60, 48] if reverse else [60, 72, 84, 96]
                        samples.extend(contact_series(heights, key))
                        metadata.append({"case": key, "entered": True, "crossed": True,
                                         "stopPauseRestart": True, "noRootPlacementAfterDeclaredSetup": True})
            (run / "samples.jsonl").write_text("\n".join(json.dumps(s) for s in samples))
            (run / "terrain-cases.json").write_text(json.dumps(metadata))
            (run / "terrain-results.json").write_text(json.dumps({"cases": metadata, "complete16Cases": True}))
            self.assertTrue(audit_run(raw, run)["complete16CasesVerified"])
            missing_key = metadata[-1]["case"]
            (run / "samples.jsonl").write_text("\n".join(json.dumps(s) for s in samples if not s["case"].startswith(missing_key)))
            self.assertFalse(audit_run(raw, run)["complete16CasesVerified"])

    def test_numeric_vectors_and_nonfinite_input(self):
        self.assertEqual(vector([1, 2, 3]), vector("(1.0, 2.0, 3.0)"))
        with self.assertRaises(ValueError): vector("(1, nan, 3)")

    def test_run_rejection_hash_completion_and_forged_matrix_claim(self):
        raw = json.dumps(WORLD).encode()
        with tempfile.TemporaryDirectory() as folder:
            run = Path(folder)
            source = {"fixtureWorldSha256": hashlib.sha256(raw).hexdigest()}
            (run / "source.json").write_text(json.dumps(source))
            (run / "samples.jsonl").write_text("\n".join(json.dumps(s) for s in contact_series([60, 72, 84, 96])))
            meta = [{"case": KEY, "entered": True, "crossed": True, "stopPauseRestart": True,
                     "noRootPlacementAfterDeclaredSetup": True}]
            (run / "terrain-cases.json").write_text(json.dumps(meta))
            (run / "terrain-results.json").write_text(json.dumps({"cases": meta, "complete16Cases": True}))
            result = audit_run(raw, run)
            self.assertEqual(result["status"], "pass_selected_cases")
            self.assertFalse(result["complete16CasesVerified"])
            (run / "rejected.json").write_text(json.dumps({"message": "original ankle guard failed"}))
            result = audit_run(raw, run)
            self.assertEqual(result["status"], "fail")
            self.assertEqual(result["originalRejection"], "original ankle guard failed")
            (run / "rejected.json").unlink()
            source["fixtureWorldSha256"] = "wrong"
            (run / "source.json").write_text(json.dumps(source))
            self.assertEqual(audit_run(raw, run)["status"], "fail")


if __name__ == "__main__":
    unittest.main()
