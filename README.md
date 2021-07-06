# Python-Venv package

A general purpose python environment that should run all of our code, together with an installation script.

Recommended usage:

```bash
bash make_env.sh -m venv
```

This will create a conda environment `venv` with the packages specifies in the `venv.yaml` file.
The `-m` flag makes the script use mamba instead of conda during the installation, which offers
way faster dependecy resolving.

## Other options:

- `-c --cache` : make conda PIP use CONDA_PREFIX/.cache/pip as cache dir (default=on)
- `-f --file ` : path to the environment file (default=venv.yaml)
- `-h --help ` : print this help
- `-m --mamba` : use mamba for installing packages (faster&better dependecy solving)
- `-y --yes  ` : passes -y flag to all options (default=off)
