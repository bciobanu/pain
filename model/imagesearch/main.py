from __future__ import print_function

import argparse
import os
import time

import torch
import torch.nn as nn
import torch.optim as optim
from imagesearch.model import Autoencoder
from imagesearch.inputs import load_data
from imagesearch.util import AverageMeter, accuracy, save_checkpoint

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


def train(train_loader, model, criterion, optimizer, epoch, print_freq):
    batch_time = AverageMeter()
    data_time = AverageMeter()
    losses = AverageMeter()
    acc = AverageMeter()

    # switch to train mode
    model.train()

    start = time.time()
    for i, (images, _) in enumerate(train_loader):
        data_time.update(time.time() - start)
        images = images.cuda()
        targets = images

        # compute y_pred
        y_pred = model(images)
        loss = criterion(y_pred, targets)

        # measure accuracy and record loss
        prec1, prec1 = accuracy(y_pred.data, targets, topk=(1, 1))
        losses.update(loss.data[0], images.size(0))
        acc.update(prec1[0], images.size(0))

        # compute gradient and do optimizer step
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        # measure elapsed time
        batch_time.update(time.time() - start)
        start = time.time()

        if i % print_freq == 0:
            print('Epoch: [{0}][{1}/{2}]\t'
                  'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                  'Data {data_time.val:.3f} ({data_time.avg:.3f})\t'
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'
                  'Accuracy {acc.val:.3f} ({acc.avg:.3f})'.format(
                    epoch, i, len(train_loader), batch_time=batch_time, data_time=data_time, loss=losses, acc=acc))


def validate(val_loader, model, criterion, print_freq):
    batch_time = AverageMeter()
    losses = AverageMeter()
    acc = AverageMeter()

    # switch to eval mode
    model.eval()

    start = time.time()
    for i, (images, _) in enumerate(val_loader):
        images = images.cuda()
        targets = images

        # compute y_pred
        y_pred = model(images)
        loss = criterion(y_pred, targets)

        # measure accuracy and record loss
        prec1, _ = accuracy(y_pred.data, targets, topk=(1, 1))
        losses.update(loss.data[0], images.size(0))
        acc.update(prec1[0], images.size(0))

        # measure elapsed time
        batch_time.update(time.time() - start)
        start = time.time()

        if i % print_freq == 0:
            print('TrainVal: [{0}/{1}]\t'
                  'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'
                  'Accuracy {acc.val:.3f} ({acc.avg:.3f})'.format(
                    i, len(val_loader), batch_time=batch_time, loss=losses, acc=acc))

    print(' * Accuracy {acc.avg:.3f}'.format(acc=acc))
    return acc.avg


def main():
    args = parser.parse_args()

    best_prec = 0
    model = Autoencoder().cuda()

    if args.resume:
        if os.path.isfile(args.resume):
            print("=> loading checkpoint '{}'".format(args.resume))
            checkpoint = torch.load(args.resume)
            args.start_epoch = checkpoint['epoch']
            best_prec = checkpoint['best_prec']
            model.load_state_dict(checkpoint['state_dict'])
            print("=> loaded checkpoint '{}' (epoch {})".format(args.evaluate, checkpoint['epoch']))
        else:
            print("=> no checkpoint found at '{}'".format(args.resume))

    traindir = os.path.join(args.data, "train")
    valdir = os.path.join(args.data, "dev")
    testdir = os.path.join(args.data, "test")

    train_loader = load_data(traindir, num_workers=args.workers, batch_size=args.batch_size)
    val_loader = load_data(valdir, num_workers=args.workers, batch_size=args.batch_size)
    test_loader = load_data(testdir, num_workers=args.workers, batch_size=args.batch_size)

    if args.test:
        return

    if args.evaluate:
        return

    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=args.lr, weight_decay=args.weight_decay)

    for epoch in range(args.start_epoch, args.epochs):
        train(train_loader, model, criterion, optimizer, epoch, args.print_freq)
        prec = validate(val_loader, model, criterion, args.print_freq)
        is_best = prec > best_prec
        best_prec = max(best_prec, prec)
        save_checkpoint({
            'epoch': epoch + 1,
            'arch': args.arch,
            'state_dict': model.state_dict(),
            'best_prec': best_prec,
        }, is_best)


if __name__ == "__main__":
    main()