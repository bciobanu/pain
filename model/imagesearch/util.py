import torch


class AverageMeter(object):
    """Computes and stores the average and current value"""

    def __init__(self):
        self.reset()

    def reset(self):
        self.val = 0
        self.avg = 0
        self.sum = 0
        self.cnt = 0

    def update(self, val, n=1):
        self.val = val
        self.sum += n * val
        self.cnt += n
        self.avg = self.sum / self.cnt


def save_checkpoint(
    state, is_best, filename="checkpoint.pth", bestname="model_best.pth", no_ckpt=False
):
    if not no_ckpt:
        torch.save(state, filename)
    if is_best:
        torch.save(state, bestname)
