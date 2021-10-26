#!/usr/bin/env bash

python -m pip install git+https://github.com/jpmorganchase/jupyterlab_templates.git
jupyter labextension install jupyterlab_templates
jupyter serverextension enable --py jupyterlab_templates

cd $CONDA_PREFIX/lib/python3.9/site-packages/jupyterlab_templates/templates
rm -rf jupyterlab_templates
ln -s  ~/Templates jupyterlab_templates
