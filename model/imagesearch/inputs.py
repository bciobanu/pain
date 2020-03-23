import torch.utils.data as data
import torchvision.datasets as datasets
import torchvision.transforms as transforms


def load_data(path, num_workers, batch_size=1):
    normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    loader = data.DataLoader(
        datasets.ImageFolder(path,
                             transforms.Compose([
                                 transforms.Resize(256),
                                 transforms.CenterCrop(256),
                                 transforms.ToTensor(),
                                 normalize
                             ])),
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers
    )
    return loader
