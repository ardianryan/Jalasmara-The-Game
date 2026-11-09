import math
import unittest
from audit_ramp_curve import COS, TAN, Ground


class RampMetricTests(unittest.TestCase):
    def setUp(self):
        self.ground = Ground({'landMaps': {'hub': {
            'terraces': [{'id': 'dock', 'elevation': 0}, {'id': 'court', 'elevation': 1}],
            'surfaces': [{'polygon': [[-100, 1000], [100, 1000], [100, 1300], [-100, 1300]], 'elevation': 0}],
            'stairs': [{'id': 'ramp', 'type': 'ramp', 'from': 'dock', 'to': 'court', 'steps': 1,
                        'path': [[0, 1190], [0, 1125]], 'width': 150}]}}})

    def test_piecewise_xyz_arc_and_inverse_against_analytic_slopes(self):
        a, b = (0, 1210), (0, 1160)
        ramp_xy_slope = 1/COS - (48/65)*TAN
        flat_xy = 20/COS
        ramp_xy = 30*ramp_xy_slope
        ramp_z = 30*48/65
        cuts, _, xy, xyz = self.ground.metrics(a, b, True)
        self.assertEqual(cuts, [0, .4, 1])
        self.assertAlmostEqual(xy, flat_xy+ramp_xy)
        self.assertAlmostEqual(xyz, flat_xy+math.hypot(ramp_xy, ramp_z))
        point = self.ground.inverse(a, b, flat_xy+10, True)
        self.assertAlmostEqual(point[1], 1190-10/ramp_xy_slope)

    def test_equal_xy_total_does_not_prove_chord_inverse_correct(self):
        a, b = (0, 1210), (0, 1160)
        old = self.ground.metrics(a, b, False)
        new = self.ground.metrics(a, b, True)
        self.assertAlmostEqual(old[2], new[2])
        self.assertGreater(new[3], old[3])
        self.assertGreater(abs(self.ground.inverse(a, b, 40, False)[1]-self.ground.inverse(a, b, 40, True)[1]), 1)


if __name__ == '__main__':
    unittest.main()
