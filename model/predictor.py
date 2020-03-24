import argparse
import json
import os
import time

import matplotlib.pyplot as plt
import numpy as np
import torch
from annoy import AnnoyIndex
from PIL import Image
from tqdm import tqdm

from imagesearch.inputs import get_transformation, load_data
from imagesearch.model import Autoencoder

parser = argparse.ArgumentParser()

parser.add_argument("--model-path", help="Location to model checkpoint", required=True)
parser.add_argument("--image-dir", help="Director of stored images", required=True)
parser.add_argument(
    "--metadata-dir",
    help="Where to store kd-tree and metadata",
    default="./predictor_metadata/",
    required=True,
)
parser.add_argument(
    "--query-path", help="Path to the image we want to do reverse search on"
)
parser.add_argument(
    "--tree-count",
    type=int,
    help="Number of actual kd-trees to store data in",
    default=1,
)
parser.add_argument(
    "--num-workers", type=int, help="Number of workers for input loading", default=4
)
parser.add_argument(
    "--generate", help="Generate kd-trees", action="store_true", default=False
)


class AnnoyLookup(object):
    def __init__(self, metadata_path):
        with open(os.path.join(metadata_path, "metadata.json")) as f:
            self._data = json.load(f)
        self._index = AnnoyIndex(self._data["feature_length"], metric="angular")
        self._index.load(os.path.join(metadata_path, "index.ann"))

    def get_neighbours(self, embedding, max_neigh=3):
        items, distances = self._index.get_nns_by_vector(
            embedding, max_neigh, include_distances=True
        )
        zipped = zip(items, distances)
        sorted_list = sorted(zipped, key=lambda t: t[1])
        return [
            (self._data["filenames"][idx], distance) for idx, distance in sorted_list
        ]


def main():
    args = parser.parse_args()

    model = Autoencoder().cuda()
    if os.path.isfile(args.model_path):
        print("=> loading checkpoint '{}'".format(args.model_path))
        checkpoint = torch.load(args.model_path)
        model.load_state_dict(checkpoint["state_dict"])
        print("=> loaded checkpoint")
    else:
        print("=> no checkpoint found at '{}'".format(args.resume))
        return
    model.eval()

    if args.generate:
        image_loader = load_data(args.image_dir, args.num_workers)
        predictions = []
        with torch.no_grad():
            predictions = [
                (path, model.encoder(image.cuda())[0].cpu().numpy().flatten())
                for image, path in image_loader
            ]
        image_paths = [path[0] for path, _ in predictions]
        image_embeddings = np.array([emb for _, emb in predictions])
        # normalize embeddings
        image_embeddings_norm = image_embeddings / image_embeddings.max()
        feature_length = len(image_embeddings_norm[0])

        filenames = []
        nn_search = AnnoyIndex(feature_length)
        for i in tqdm(range(len(image_paths))):
            nn_search.add_item(i, image_embeddings_norm[i])
            filenames.append(image_paths[i])

        with open("{}/metadata.json".format(args.metadata_dir), "w") as outfile:
            json.dump(
                {
                    "timestamp": time.time(),
                    "feature_length": feature_length,
                    "filenames": filenames,
                },
                outfile,
            )

        nn_search.build(args.tree_count)
        nn_search.save("{}/index.ann".format(args.metadata_dir))
        print("Successfully indexed {} images".format(len(filenames)))

    if args.query_path:
        img = Image.open(args.query_path).convert("RGB")
        transform = get_transformation()
        img = transform(img)
        img = img.unsqueeze(0)
        img = img.cuda()
        embedding = None
        with torch.no_grad():
            embedding = model.encoder(img).cpu().numpy().flatten()

        annoy_lookup = AnnoyLookup(args.metadata_dir)
        res = annoy_lookup.get_neighbours(embedding)

        for filename, distance in res:
            figure = plt.figure()
            plt.title(str(distance))
            image = plt.imread(os.path.join(args.image_dir, filename))
            plt.imshow(image)
        plt.show()


if __name__ == "__main__":
    main()
