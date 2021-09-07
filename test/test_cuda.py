import logging
from termcolor import colored

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logging.info("")   # BUG: if this is missing then the first log message is missing?
success = lambda s: logger.info(colored(s + "  \N{HEAVY CHECK MARK}", "green", attrs=["bold"]))
failure = lambda s: logger.info(colored(s + "  \N{HEAVY BALLOT X}", "red", attrs=["bold"]))


def test_jax_cuda():
    try:
        import jax
    except:
        failure("JAX+CPU")
    else:
        success("JAX+CPU")
    try:
        assert any(['gpu' in str(device) for device in jax.devices()])
    except:
        failure("JAX+CUDA")
    else:
        success("JAX+CUDA")


def test_torch_cuda():
    try:
        import torch
    except:
        failure("TORCH+CPU")
    else:
        success("TORCH+CPU")
    try:
        assert torch.cuda.is_available()
    except:
        failure("TORCH+CUDA")
    else:
        success("TORCH+CUDA")


def test_tf_gpu():
    try:
        import tensorflow as tf
    except:
        failure("TF+CPU")
    else:
        success("TF+CPU")
    try:
        assert len(tf.config.list_physical_devices('GPU')) >= 1
    except:
        failure("TF+CUDA")
    else:
        success("TF+CUDA")


def test_mx_gpu():
    try:
        import mxnet as mx
    except:
        failure("MX+CPU")
    else:
        success("MX+CPU")
    try:
        a = mx.nd.ones((2, 3), mx.gpu())
    except:
        failure("MX+CUDA")
    else:
        success("MX+CUDA")


if __name__ == "__main__":
    test_jax_cuda()
    test_torch_cuda()
    test_tf_gpu()
    test_mx_gpu()
