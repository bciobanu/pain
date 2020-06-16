import unittest

import handler


class TestHandler(unittest.TestCase):
    def test_prediction(self):
        handler.load("./data_overfit/train", model_path="./model_best_test.pth")
        best = handler.predict("./data_overfit/test/2.jpg")
        self.assertEqual(
            best[0], "The-Persistence-of-Memory-canvas-collection-Salvador-1931.jpg"
        )

    def test_add_and_predict(self):
        handler.load("./data_overfit/train", model_path="./model_best_test.pth")
        handler.add_alexnet_image("./data/train/0.jpg")
        handler.add_alexnet_image("./data/train/1.jpg")
        best = handler.predict("./data/train/0.jpg")
        self.assertEqual(best[0], "0.jpg")


if __name__ == "__main__":
    unittest.main()
