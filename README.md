# Python-Venv package

A general purpose python environment that should run all of our code, together with an installation script.

Recommended usage:

```bash
./make_env.sh venv -y -m --cuda-jax --cuda-mx
```

This will create a conda environment `venv` with the packages specifies in the `venv.yaml` file.
The `-m` flag makes the script use mamba instead of conda during the installation, which offers
way faster dependecy resolving.

## Other options

- `-c --cache` : specify PIP cache directory (default: check if ~/.cache/pip exists)
- `-f --file` : path to the environment file (default=venv.yaml)
- `-h --help` : print this help
- `-m --mamba` : use mamba for installing packages (faster&better dependecy solving)
- `-y --yes` : passes -y flag to all options (default=off)
- `--cuda-*` : install various cuda versions.
