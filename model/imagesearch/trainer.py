from __future__ import print_function

import time
import os

from imagesearch.util import AverageMeter
from torchvision.utils import save_image


def train(train_loader, model, criterion, optimizer, epoch, print_freq):
    batch_time = AverageMeter()
    data_time = AverageMeter()
    losses = AverageMeter()

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

        # record loss
        losses.update(loss.data, images.size(0))

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
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'.format(
                    epoch, i + 1, len(train_loader), batch_time=batch_time, data_time=data_time, loss=losses))
    return losses.avg


def validate(val_loader, model, criterion, print_freq):
    batch_time = AverageMeter()
    losses = AverageMeter()

    # switch to eval mode
    model.eval()

    start = time.time()
    for i, (images, _) in enumerate(val_loader):
        images = images.cuda()
        targets = images

        # compute y_pred
        y_pred = model(images)
        loss = criterion(y_pred, targets)

        # record loss
        losses.update(loss.data, images.size(0))

        # measure elapsed time
        batch_time.update(time.time() - start)
        start = time.time()

        if i % print_freq == 0:
            print('TrainVal: [{0}/{1}]\t'
                  'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'.format(
                    i + 1, len(val_loader), batch_time=batch_time, loss=losses))

    print(' * Loss {loss.avg:.3f}'.format(loss=losses))
    return losses.avg


def test(test_loader, model, criterion, output_dir):
    # switch to eval mode
    model.eval()

    for i, (image, path) in enumerate(test_loader):
        filename = os.path.basename(path[0])
        filename, ext = os.path.splitext(filename)
        image = image.cuda()
        y_pred = model(image)
        loss = criterion(y_pred, image)
        print(f"{filename} : Loss = {loss}")
        save_image(image, os.path.join(output_dir, filename + ext))
        save_image(y_pred, os.path.join(output_dir, filename + "_output" + ext))
