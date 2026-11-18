"""Checks that the new props keep a hand/tool connection and a legible page shape."""

from collections import deque
from unittest import TestCase, main

from author_beno_jala import beno_jala, smarapedia


class ProloguePropTest(TestCase):
    def test_jala_is_connected_to_benos_hand(self) -> None:
        art = beno_jala()
        self.assertEqual(art.size, (64, 64))
        seen = {(41, 23)}
        queue = deque(seen)
        while queue:
            x, y = queue.popleft()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                p = (x + dx, y + dy)
                if 0 <= p[0] < 64 and 0 <= p[1] < 64 and art.getpixel(p)[3] and p not in seen:
                    seen.add(p)
                    queue.append(p)
        self.assertIn((45, 8), seen)
        self.assertIn((43, 18), seen)
        self.assertIn((43, 23), seen)

    def test_smarapedia_has_two_pages_and_copper_spine(self) -> None:
        art = smarapedia()
        self.assertEqual(art.size, (48, 32))
        left = art.getpixel((12, 18))
        right = art.getpixel((35, 18))
        spine = art.getpixel((24, 18))
        self.assertEqual(left, right)
        self.assertNotEqual(spine, left)
        self.assertEqual(art.getpixel((0, 0))[3], 0)


if __name__ == "__main__":
    main()
