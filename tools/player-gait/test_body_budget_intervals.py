import unittest

from model_restart_body_budget import common_hip_intervals, intersection, line_sphere_interval


class BodyBudgetIntervals(unittest.TestCase):
    def test_stationary_inside_and_outside(self):
        self.assertEqual(line_sphere_interval([0, 0, 0], [0, 0, 0], [0, 0, 0], 1, 2, 5), [(2, 5)])
        self.assertEqual(line_sphere_interval([2, 0, 0], [0, 0, 0], [0, 0, 0], 1, 2, 5), [])

    def test_entering_and_leaving_sphere_are_both_bounded(self):
        result = line_sphere_interval([5, 0, 0], [-1, 0, 0], [0, 0, 0], 2, 0, 10)
        self.assertEqual(result, [(3, 7)])

    def test_no_intersection_does_not_invent_duration(self):
        self.assertEqual(line_sphere_interval([0, 3, 0], [1, 0, 0], [0, 0, 0], 2, 0, 10), [])

    def test_piecewise_shared_boundary_merges_without_relaxation(self):
        self.assertEqual(intersection([(1, 8)], [(2, 4), (4, 6)]), [(2, 6)])

    def test_disjoint_duration_options_stay_disjoint(self):
        self.assertEqual(intersection([(1, 8)], [(0, 2), (5, 9)]), [(1, 2), (5, 8)])

    def test_both_legs_need_the_same_height(self):
        xy = {"left": [0, 0], "right": [0, 0]}
        self.assertEqual(common_hip_intervals(xy, {"left": [0, 0, 0], "right": [0, 0, 5]},
                                            {"left": (0, 2), "right": (0, 2)}, -10, 10), [])
        self.assertEqual(common_hip_intervals(xy, {"left": [0, 0, 0], "right": [0, 0, 3]},
                                            {"left": (0, 2), "right": (0, 2)}, -10, 10), [(1, 2)])

    def test_inner_annulus_preserves_two_disjoint_height_options(self):
        self.assertEqual(common_hip_intervals({"left": [0, 0]}, {"left": [0, 0, 0]},
                                            {"left": (1, 3)}, -4, 4), [(-3, -1), (1, 3)])

    def test_horizontal_tangent_matches_strict_runtime_rejection(self):
        self.assertEqual(common_hip_intervals({"left": [3, 0]}, {"left": [0, 0, 0]},
                                            {"left": (0, 3)}, -1, 1), [])

    def test_variable_pelvis_can_fit_when_maximum_drop_does_not(self):
        allowed = common_hip_intervals({"left": [0, 0], "right": [0, 0]},
                                       {"left": [0, 0, 10], "right": [0, 0, 0]},
                                       {"left": (0, 8), "right": (0, 8)}, 0, 8)
        self.assertEqual(allowed, [(2, 8)])
        self.assertTrue(any(lower <= 6 <= upper for lower, upper in allowed))
        self.assertFalse(any(lower <= 0 <= upper for lower, upper in allowed))


if __name__ == "__main__":
    unittest.main()
