import unittest

from check_facing_recovery import audit


def sample(body="south", foot="south", desired="south", distance=0, paused=False):
    return {"case": "daily/false/0 travel", "physicsDelta": .1,
            "source": {"poseFrozen": paused},
            "pose": {"direction": body, "desiredDirection": desired,
                     "contacts": {"acceptedDistance": distance, "feet": {
                         side: {"footDirection": foot, "grounded": False} for side in ["left", "right"]}}}}


class FacingRecoveryTests(unittest.TestCase):
    def test_held_body_does_not_hide_held_feet(self):
        result = audit([sample("north", "north")], 1)
        self.assertEqual({row["component"] for row in result["terminalMismatches"]}, {"body", "left", "right"})
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_actual_recovery_and_free_foot_opportunity(self):
        result = audit([sample("north", "north", distance=1), sample(distance=2)], 1)
        self.assertTrue(result["terminalRecoveryAccepted"])
        self.assertEqual(result["cases"]["daily/false/0"]["left"]["recoveries"], 1)
        self.assertEqual(result["cases"]["daily/false/0"]["left"]["freeFootObservations"], 2)

    def test_adjacent_desired_changes_do_not_erase_continuous_wrong_facing(self):
        result = audit([sample("north", "north", desired="west", distance=1),
                        sample("north", "north", desired="south", distance=2)], 1)
        state = result["cases"]["daily/false/0"]["body"]
        self.assertAlmostEqual(state["maxHeldSeconds"], .2)
        self.assertEqual(state["maxHeldAcceptedDistance"], 2)

    def test_pause_does_not_accumulate_movement_hold(self):
        result = audit([sample("north", "north", distance=1), sample("north", "north", distance=1, paused=True)], 1)
        state = result["cases"]["daily/false/0"]["left"]
        self.assertAlmostEqual(state["maxHeldSeconds"], .1)
        self.assertEqual(state["freeFootObservations"], 1)

    def test_partial_matrix_is_not_recovery_acceptance(self):
        result = audit([sample()], 32)
        self.assertEqual(result["missingCases"], 31)
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_missing_pose_is_insufficient_observation(self):
        row = sample()
        del row["pose"]["contacts"]["feet"]["left"]["footDirection"]
        result = audit([row], 1)
        self.assertFalse(result["completeCaseSet"])

    def test_rejected_run_cannot_pass_even_if_last_valid_pose_matches(self):
        result = audit([sample()], 1, [{"message": "original reach rejection"}])
        self.assertFalse(result["terminalRecoveryAccepted"])

    def test_matching_intermediate_artwork_does_not_hide_requested_direction_lag(self):
        row = sample("north", "north", desired="north")
        row["source"]["requestedDirection"] = "south"
        result = audit([row], 1)
        self.assertEqual(len(result["terminalMismatches"]), 3)
        self.assertEqual(result["cases"]["daily/false/0"]["artworkDirections"], ["north"])
        self.assertEqual(result["cases"]["daily/false/0"]["requestedDirectionObservations"], 1)


if __name__ == "__main__":
    unittest.main()
