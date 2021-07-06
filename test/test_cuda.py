import logging

logger = logging.getLogger(__name__)


def test_jax_cuda():
    import jax
    assert any(['gpu' in str(device) for device in jax.devices()])
    logger.info("CUDA available for JAX")


def test_torch_cuda():
    import torch
    assert torch.cuda.is_available()
    logger.info("CUDA available for Torch")


def test_tf_gpu():
    import tensorflow as tf
    assert len(tf.config.list_physical_devices('GPU')) >= 1
    logger.info("CUDA available for TensorFlow")


if __name__ == "__main__":
    logger.setLevel(logging.INFO)
    test_jax_cuda()
    test_torch_cuda()
    test_tf_gpu()
