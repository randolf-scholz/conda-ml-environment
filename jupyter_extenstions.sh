#!/usr/bin/env bash

pip install jupyterlab_templates
jupyter labextension install jupyterlab_templates
jupyter serverextension enable --py jupyterlab_templates
cd $CONDA_PREFIX/lib/python3.9/site-packages/jupyterlab_templates/templates
ln -s  ~/Documents/Templates jupyterlab_templates
