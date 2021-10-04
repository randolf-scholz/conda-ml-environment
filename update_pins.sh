cp pinned $CONDA_PREFIX/conda-meta/pinned
PINNED=$(python3 split.py "$(cat pinned)")
conda update --all $PINNED