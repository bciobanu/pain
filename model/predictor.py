import argparse
import json
import os
import time

import numpy as np
import torch
import torch.nn as nn
from annoy import AnnoyIndex
from torchvision import models
from tqdm import tqdm

from imagesearch.inputs import load_data
from imagesearch.model import Autoencoder


class Identity(nn.Module):
    def __init__(self):
        super(Identity, self).__init__()

    def forward(self, x):
        return x


parser = argparse.ArgumentParser()

parser.add_argument("--model-path", help="Location to model checkpoint")
parser.add_argument("--image-dir", help="Director of stored images", required=True)
parser.add_argument(
    "--metadata-dir",
    help="Where to store kd-tree and metadata",
    default="./predictor_metadata/",
    required=True,
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
    args.use_alexnet = not args.model_path

    if args.use_alexnet:
        model = models.alexnet(pretrained=True).cuda()
        model.classifier[6] = Identity().cuda()
        args.center_crop = 224
    else:
        model = Autoencoder().cuda()
        args.center_crop = 256
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
        image_loader = load_data(
            args.image_dir, args.num_workers, center_crop=args.center_crop
        )
        predictions = []
        with torch.no_grad():
            predictions = [
                (
                    path,
                    (
                        model(image.cuda())
                        if args.use_alexnet
                        else model.encoder(image.cuda())
                    )[0]
                    .cpu()
                    .numpy()
                    .flatten(),
                )
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


if __name__ == "__main__":
    main()
