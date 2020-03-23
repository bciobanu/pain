import torch.nn as nn


class Autoencoder(nn.Module):
    def __init__(self):
        super(Autoencoder, self).__init__()
        self.encoder = nn.Sequential(
            nn.Conv2d(3, 16, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(16, 32, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(32, 64, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(64, 128, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(128, 256, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(256, 512, 3, stride=2, padding="same"),
            nn.ReLU(True)
        )
        self.decoder = nn.Sequential(
            nn.Conv2d(512, 512, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(512, 256, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(256, 128, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(128, 64, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(64, 32, 3, stride=2, padding="same"),
            nn.ReLU(True),
            nn.Conv2d(32, 3, 3, stride=2, padding="same"),
            nn.ReLU(True)
        )

    def forward(self, x):
        x = self.encoder(x)
        x = self.decoder(x)
        return x
