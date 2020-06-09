import ssl

ssl._create_default_https_context = ssl._create_unverified_context

import logging
import ntpath
import os
from collections import Counter, deque

import numpy as np
import torch
import torch.nn as nn
from annoy import AnnoyIndex
from PIL import Image
from torchvision import models

from imagesearch.inputs import get_transformation, load_data
from imagesearch.model import Autoencoder
from run_model import main as run_model_main

logger = logging.getLogger(__file__)
logger.setLevel(logging.INFO)

CENTER_CROP_MODEL = 256
CENTER_CROP_ALEXNET = 224

model = None
alexnet = None
is_cuda_available = torch.cuda.is_available()
device = torch.device("cuda" if is_cuda_available else "cpu")
logger.info("Using GPU: " + str(is_cuda_available))

filenames = []
index_model = None
index_alexnet = deque([])
index_alexnet_sizes = deque([])


class Identity(nn.Module):
    def __init__(self):
        super(Identity, self).__init__()

    def forward(self, x):
        return x


def generate_kdtree_(net, image_folder, center_crop, num_workers=4):
    global filenames

    image_loader = load_data(image_folder, num_workers, center_crop=center_crop)
    with torch.no_grad():
        predictions = [
            (pth, net(img.to(device))[0].cpu().numpy().flatten(),)
            for img, pth in image_loader
        ]
    image_names = [pth[0] for pth, _ in predictions]
    image_embeddings = np.array([emb for _, emb in predictions])
    # normalize embeddings
    image_embeddings_norm = [emb / np.linalg.norm(emb) for emb in image_embeddings]
    try:
        feature_length = len(image_embeddings_norm[0])
    except IndexError:
        feature_length = 0

    filenames = image_names
    kd_tree = AnnoyIndex(feature_length)
    for i in range(len(filenames)):
        kd_tree.add_item(i, image_embeddings_norm[i])
    kd_tree.build(1)
    logger.info("Successfully indexed {} images".format(len(filenames)))
    return kd_tree


def load(image_folder, model_path="./model_best.pth", num_workers=4):
    global alexnet
    global model
    global index_model
    global index_alexnet
    global index_alexnet_sizes

    model = Autoencoder().to(device)
    if os.path.isfile(model_path):
        logger.info("=> loading checkpoint '{}'".format(model_path))
        checkpoint = torch.load(model_path)
        model.load_state_dict(checkpoint["state_dict"])
        logger.info("=> loaded checkpoint")
    else:
        logger.error("no checkpoint found at '{}'".format(model_path))
    index_model = generate_kdtree_(
        model.encoder, image_folder, CENTER_CROP_MODEL, num_workers=num_workers
    )

    alexnet = models.alexnet(pretrained=True).to(device)
    assert alexnet
    alexnet.classifier[6] = Identity().to(device)
    index_alexnet = deque(
        [
            generate_kdtree_(
                alexnet, image_folder, CENTER_CROP_ALEXNET, num_workers=num_workers
            )
        ]
    )
    index_alexnet_sizes = deque([len(filenames)])


def get_image_emb_(net, image_path, center_crop):
    img = Image.open(image_path).convert("RGB")
    transform = get_transformation(center_crop=center_crop)
    img = transform(img)
    img = img.unsqueeze(0)
    img = img.to(device)
    with torch.no_grad():
        embedding = net(img).cpu().numpy().flatten()
    embedding = embedding / np.linalg.norm(embedding)
    return embedding


def add_alexnet_image(image_path):
    global alexnet
    global index_alexnet
    global index_alexnet_sizes
    global filenames

    embedding = get_image_emb_(alexnet, image_path, CENTER_CROP_ALEXNET)
    feature_length = len(embedding)
    file = ntpath.basename(image_path)
    filenames.append(file)

    embs = [(len(filenames) - 1, embedding)]
    last = len(filenames) - 2
    while len(index_alexnet) > 0 and index_alexnet_sizes[-1] == len(embs):
        first = last - len(embs) + 1
        for i in range(first, last + 1):
            embs.append((i, index_alexnet[-1].get_item_vector(i)))
        index_alexnet.pop()
        index_alexnet_sizes.pop()

    kd_tree = AnnoyIndex(feature_length)
    for i, e in embs:
        kd_tree.add_item(i, e)
    kd_tree.build(1)
    index_alexnet.append(kd_tree)
    index_alexnet_sizes.append(len(embs))


def predict_(image_path, top_n=5):
    global model
    global alexnet
    global index_model
    global index_alexnet
    global filenames

    # top n Model
    if model and index_model:
        model_emb = get_image_emb_(model.encoder, image_path, CENTER_CROP_MODEL)
        items, distances = index_model.get_nns_by_vector(
            model_emb, top_n, include_distances=True
        )
        zipped = zip(items, distances)
        sorted_list = sorted(zipped, key=lambda t: t[1])
        best_from_model = [(filenames[idx], dst) for idx, dst in sorted_list]
    else:
        best_from_model = []

    # top n AlexNet
    alexnet_emb = get_image_emb_(alexnet, image_path, CENTER_CROP_ALEXNET)
    best_from_alexnet = []
    for kd in index_alexnet:
        items, distances = kd.get_nns_by_vector(
            alexnet_emb, top_n, include_distances=True
        )
        zipped = zip(items, distances)
        best_from_alexnet.extend(zipped)
    best_from_alexnet = sorted(best_from_alexnet, key=lambda t: t[1])
    best_from_alexnet = [(filenames[idx], dst) for idx, dst in best_from_alexnet][
        :top_n
    ]

    ctr = Counter()
    best_res = []
    for i in range(top_n):
        if i < len(best_from_alexnet) and ctr[best_from_alexnet[i][0]] == 0:
            ctr[best_from_alexnet[i][0]] += 1
            best_res.append(best_from_alexnet[i])
        if i < len(best_from_model) and ctr[best_from_model[i][0]] == 0:
            ctr[best_from_model[i][0]] += 1
            best_res.append(best_from_model[i])
    return best_res[:top_n]


def predict(image_path, top_n=5):
    best_res = predict_(image_path, top_n)
    best_res = [t[0] for t in best_res]
    return best_res


def train(
    image_folder,
    model_path="./model_best.pth",
    workers=4,
    epochs=200,
    start_epoch=0,
    batch_size=16,
    lr=1e-2,
    weight_decay=1e-4,
    resume="",
    print_freq=1,
    evaluate=False,
    test=False,
):
    class Empty:
        pass

    args = Empty()
    args.data = image_folder
    args.workers = workers
    args.epochs = epochs
    args.start_epoch = start_epoch
    args.batch_size = batch_size
    args.lr = lr
    args.weight_decay = weight_decay
    args.resume = resume
    args.print_freq = print_freq
    args.evaluate = evaluate
    args.test = test
    args.no_ckpt = True
    args.best_name = model_path
    run_model_main(args)
