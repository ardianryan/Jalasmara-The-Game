import unittest

from check_facing_recovery import audit, expected_labels


def sample(body="south", foot="south", desired="south", distance=0, paused=False):
    return {"case": "daily/false/0 travel", "physicsDelta": .1,
            "source": {"poseFrozen": paused, "requestedDirection": desired},
            "pose": {"direction": body, "desiredDirection": desired,
                     "contacts": {"acceptedDistance": distance, "feet": {
                         side: {"footDirection": foot, "grounded": False} for side in ["left", "right"]}}}}


def checked(rows, expected=1, rejections=None):
    completion = [{"declaredComplete": True, "caseKeys": ["daily/false/0"], "sourceFingerprint": "test-source"}]
    return audit(rows, expected, rejections, completion, {"daily/false/0"} if expected == 1 else None)


class FacingRecoveryTests(unittest.TestCase):
    def test_held_body_does_not_hide_held_feet(self):
        result = checked([sample("north", "north")], 1)
        self.assertEqual({row["component"] for row in result["terminalMismatches"]}, {"body", "left", "right"})
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_actual_recovery_and_free_foot_opportunity(self):
        result = checked([sample("north", "north", distance=1), sample(distance=2)], 1)
        self.assertTrue(result["terminalRecoveryAccepted"])
        self.assertEqual(result["cases"]["daily/false/0"]["left"]["recoveries"], 1)
        self.assertEqual(result["cases"]["daily/false/0"]["left"]["freeFootObservations"], 2)

    def test_adjacent_desired_changes_do_not_erase_continuous_wrong_facing(self):
        result = checked([sample("north", "north", desired="west", distance=1),
                        sample("north", "north", desired="south", distance=2)], 1)
        state = result["cases"]["daily/false/0"]["body"]
        self.assertAlmostEqual(state["maxHeldSeconds"], .2)
        self.assertEqual(state["maxHeldAcceptedDistance"], 2)

    def test_pause_does_not_accumulate_movement_hold(self):
        result = checked([sample("north", "north", distance=1), sample("north", "north", distance=1, paused=True)], 1)
        state = result["cases"]["daily/false/0"]["left"]
        self.assertAlmostEqual(state["maxHeldSeconds"], .1)
        self.assertEqual(state["freeFootObservations"], 1)

    def test_partial_matrix_is_not_recovery_acceptance(self):
        result = checked([sample()], 32)
        self.assertEqual(result["missingCases"], 31)
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_missing_pose_is_insufficient_observation(self):
        row = sample()
        del row["pose"]["contacts"]["feet"]["left"]["footDirection"]
        result = checked([row], 1)
        self.assertFalse(result["completeCaseSet"])

    def test_rejected_run_cannot_pass_even_if_last_valid_pose_matches(self):
        result = checked([sample()], 1, [{"message": "original reach rejection"}])
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_matching_intermediate_artwork_does_not_hide_requested_direction_lag(self):
        row = sample("north", "north", desired="north")
        row["source"]["requestedDirection"] = "south"
        result = checked([row], 1)
        self.assertEqual(len(result["terminalMismatches"]), 3)
        self.assertEqual(result["cases"]["daily/false/0"]["artworkDirections"], ["north"])
        self.assertEqual(result["cases"]["daily/false/0"]["requestedDirectionObservations"], 1)

    def test_legacy_artwork_fallback_is_insufficient_for_raw_request_acceptance(self):
        row = sample()
        del row["source"]["requestedDirection"]
        result = checked([row], 1)
        self.assertEqual(result["rawRequestedInsufficientCases"], ["daily/false/0"])
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_declared_initial_setup_does_not_count_as_missing_movement_request(self):
        initial = sample()
        initial["fixtureInitial"] = True
        del initial["source"]
        result = checked([initial, sample(distance=1)], 1)
        self.assertEqual(result["rawRequestedInsufficientCases"], [])
        self.assertTrue(result["terminalRecoveryAccepted"])

    def test_one_matching_observation_per_canonical_case_is_not_completed_matrix(self):
        rows = []
        for label in sorted(expected_labels(32)):
            row = sample()
            row["case"] = label + " travel"
            rows.append(row)
        result = audit(rows, 32)
        self.assertTrue(result["observedCaseCoverage"])
        self.assertTrue(result["observedExpectedIdentities"])
        self.assertFalse(result["completionProofAccepted"])
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_thirty_two_arbitrary_labels_cannot_satisfy_completed_identities(self):
        rows = []
        for index in range(32):
            row = sample()
            row["case"] = f"arbitrary{index} travel"
            rows.append(row)
        proof = [{"declaredComplete": True, "caseKeys": [row["case"].split()[0] for row in rows], "sourceFingerprint": "same"}]
        result = audit(rows, 32, completion=proof)
        self.assertFalse(result["completionProofAccepted"])
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_completion_proof_cannot_mix_sources(self):
        proof = [{"declaredComplete": True, "caseKeys": ["daily/false/0"], "sourceFingerprint": "first"},
                 {"declaredComplete": False, "caseKeys": [], "sourceFingerprint": "second"}]
        result = audit([sample()], 1, completion=proof, identities={"daily/false/0"})
        self.assertFalse(result["sameSourceCompletionProof"])
        self.assertFalse(result["terminalRecoveryAccepted"])


if __name__ == "__main__":
    unittest.main()
