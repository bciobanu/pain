import os

import torch.utils.data as data
import torchvision.transforms as transforms
from PIL import Image


class ImageFolderWithPaths(data.Dataset):
    def __init__(self, root, transform=None):
        images = []
        for filename in os.listdir(root):
            if filename.endswith("jpg"):
                images.append("{}".format(filename))

        self.root = root
        self.imgs = images
        self.transform = transform

    def __getitem__(self, index):
        filename = self.imgs[index]
        img = Image.open(os.path.join(self.root, filename)).convert("RGB")

        if self.transform is not None:
            img = self.transform(img)
        return img, filename

    def __len__(self):
        return len(self.imgs)


def get_transformation():
    normalize = transforms.Normalize(
        mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
    )
    return transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(256),
            transforms.ToTensor(),
            normalize,
        ]
    )


def load_data(path, num_workers, batch_size=1):
    loader = data.DataLoader(
        ImageFolderWithPaths(path, get_transformation(),),
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
    )
    return loader
