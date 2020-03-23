from __future__ import print_function

import argparse
import os

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.tensorboard import SummaryWriter
from imagesearch.model import Autoencoder
from imagesearch.inputs import load_data
from imagesearch.util import save_checkpoint
from imagesearch.trainer import train, validate, test

parser = argparse.ArgumentParser(description="Image reverse search")
parser.add_argument('data', metavar='DIR', help='path to dataset')
parser.add_argument('--workers', default=4, type=int, metavar='N', help='number of data loading workers (default: 4)')
parser.add_argument('--epochs', default=90, type=int, metavar='N', help='number of total epochs to run')
parser.add_argument('--start-epoch', default=0, type=int, metavar='N', help='manual epoch number (useful on restarts)')
parser.add_argument('-b', '--batch-size', default=16, type=int, metavar='N', help='mini-batch size (default: 256)')
parser.add_argument('--lr', '--learning-rate', default=1e-2, type=float, metavar='LR', help='initial learning rate')
parser.add_argument('--weight-decay', default=1e-4, type=float, metavar='W', help='weight decay')
parser.add_argument('--resume', default='', type=str, metavar='PATH', help='path to latest checkpoint')
parser.add_argument('--print-freq', default=1, type=int, metavar='N', help='print frequency')
parser.add_argument('--evaluate', dest='evaluate', action='store_true', help='evaluate model on validation set')
parser.add_argument('--test', dest='test', action='store_true', help='evaluate model on test set')


def main():
    args = parser.parse_args()
    writer = SummaryWriter()

    best_loss = float("Inf")
    model = Autoencoder().cuda()
    criterion = nn.MSELoss().cuda()
    optimizer = optim.Adam(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)

    if args.resume:
        if os.path.isfile(args.resume):
            print("=> loading checkpoint '{}'".format(args.resume))
            checkpoint = torch.load(args.resume)
            args.start_epoch = checkpoint['epoch']
            best_loss = checkpoint['best_loss']
            model.load_state_dict(checkpoint['state_dict'])
            optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
            print("=> loaded checkpoint '{}' (epoch {})".format(args.evaluate, checkpoint['epoch']))
            print("=> Best loss: {}".format(checkpoint['best_loss']))
        else:
            print("=> no checkpoint found at '{}'".format(args.resume))

    traindir = os.path.join(args.data, "train")
    valdir = os.path.join(args.data, "dev")
    testdir = os.path.join(args.data, "test")

    train_loader = load_data(traindir, num_workers=args.workers, batch_size=args.batch_size)
    val_loader = load_data(valdir, num_workers=args.workers, batch_size=args.batch_size)
    test_loader = load_data(testdir, num_workers=args.workers)

    if args.test:
        test(test_loader, model, criterion, os.path.join(args.data, "output_test"))
        return

    if args.evaluate:
        validate(val_loader, model, criterion, args.print_freq)
        return

    for epoch in range(args.start_epoch, args.epochs):
        train_loss = train(train_loader, model, criterion, optimizer, epoch, args.print_freq)
        validation_loss = validate(val_loader, model, criterion, args.print_freq)
        is_best = validation_loss < best_loss
        best_loss = min(best_loss, validation_loss)
        save_checkpoint({
            'epoch': epoch + 1,
            'state_dict': model.state_dict(),
            'optimizer_state_dict': optimizer.state_dict(),
            'best_loss': best_loss,
        }, is_best)
        writer.add_scalars('Loss', {'train': train_loss,
                                   'validation': validation_loss}, epoch)

    writer.close()


if __name__ == "__main__":
    main()