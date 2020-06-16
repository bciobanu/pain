import unittest
from unittest.mock import patch

import handler


class TestHandler(unittest.TestCase):
    def test_no_image_to_load(self):
        handler.load("./empty")
        self.assertEqual(handler.load_done, False)

    def test_predict_no_images(self):
        with patch("handler.load_done", False):
            res = handler.predict("")
            self.assertEqual(res, [])


if __name__ == "__main__":
    unittest.main()
