#!/usr/bin/env bash

if [ "$CONDA_DEFAULT_ENV" != "base" ]; then
	echo "Script must be executed from base environment!"
	exit 1
fi

#########
# SETUP #
#########

set -e
CONDA=conda
FILE="venv.yaml"
NON_INTERACTIVE=false
CUDA_JAX=false
CUDA_TF=false
CUDA_MX=false
PIP_CACHE_DIR=""

usage="
	$(basename "$0") [-c --cache] [-f --file] [-h --help] [-m --mamba] [-y --yes] envname

	Create a conda environment from yaml file.

	envname    : name of the environment to initialize
	-c --cache : specify PIP cache directory (default: check if ~/.cache/pip exists)
	-f --file  : path to the environment file (default=env.yaml)
	-h --help  : print this help
	-m --mamba : use mamba for installing packages (faster&better dependecy solving)
	-y --yes   : passes -y flag to all options (default=off)
	--non-interactive
	--cuda-jax : install cuda-compatible JAX
	--cuda-tf  : install cuda-compatible TensorFlow
	--cuda-mx  : install cuda-compatible MXNet
	--cuda-all : install cuda-compatible frameworks
	"

print_title () { echo -e "\n\e[32m>>> $1 <<<\e[0m"; }
print_alert () { echo -e   "\e[31m>>> $1 <<<\e[0m"; }
print_infos () { echo -e "\e[33m$1\e[0m" ; }

bool_promt () {
	# Ask user (y/n) query
	# if non-interactive, return $2 if given, else true (1)
	print_title "$1"
	auto_yes=${2:-true}

	if $NON_INTERACTIVE; then
		sleep 2
		if $auto_yes; then
			echo -e "Proceed ([y]/n)? \e[33m>>> YES\e[0m\n"
			sleep 2
			return 1
		else
			echo -e "Proceed ([y]/n)? \e[31m>>> NO\e[0m\n"
			sleep 2
			return 0
		fi
	fi

	while true; do
		read -p "Proceed ([y]/n)?" response
		case $response in
			[Yy]*) return 1;;
			[Nn]*) return 0;;
			"") return 1;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

####################
# Argument parsing #
####################

# https://stackoverflow.com/a/14203146/9318372
POSITIONAL=()
for key in "$@"; do
case $key in
	-h|--help)
	echo "$usage" >&2
	exit
	;;
	-c|--cache)
	PIP_CACHE_DIR=$key
	shift # past argument with no value
	;;
	-f|--file)
	FILE=$key
	shift # past argument with no value=
	;;
	-m|--mamba)
	CONDA=mamba
	shift # past argument with no value
	;;
	-y|--yes|--non-interactive)
	NON_INTERACTIVE=true
	shift # past argument with no value
	;;
	--cuda-jax)
	CUDA_JAX=true
	shift # past argument with no value
	;;
	--cuda-tf)
	CUDA_TF=true
	shift # past argument with no value
	;;
	--cuda-mx)
	CUDA_MX=true
	shift # past argument with no value
	;;
	--cuda-all)
	CUDA_MX=true
	CUDA_TF=true
	CUDA_JAX=true
	shift # past argument with no value
	;;
	-*|--*)
	print_alert "illegal option $key"
	echo "$usage"
	exit 1
	;;
	*)
	POSITIONAL+=("$key") # save it in an array for later
	shift # past argument
	;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters


if $NON_INTERACTIVE; then
	ARGS="-y"
else
	ARGS=""
fi

print_infos "Running non-interactively: $NON_INTERACTIVE"
print_infos "Found existing conda interpreter in $(which conda)"
if [ "$PIP_CACHE_DIR" == "" ]; then
	if [ -d "$HOME/.cache/pip" ]; then
		PIP_CACHE_DIR="$HOME/.cache/pip"
		print_infos "Found existing pip cache directory in $PIP_CACHE_DIR"
	fi
fi

remaining_args=("$@")
if [ "$remaining_args" == "" ]; then
	# if no positional was given ask user for environment name
    echo "Please enter the enviroment name:"
	read ENVNAME
else
	ENVNAME="$remaining_args"
fi

PINNED=$(python3 split.py "$(cat pinned)")

########
# MAIN #
########
print_title "Creating Environment"
print_infos "Environment Name                : $ENVNAME"
print_infos "Caching PIP packages in         : $PIP_CACHE_DIR"
print_infos "Running in non-interactive mode : $NON_INTERACTIVE"
print_infos "Using environment file          : $FILE"
print_infos "Installing packages via         : $CONDA"
sleep 3
conda create $ARGS --name $ENVNAME -c conda-forge mamba

print_title "Activing environment"
source $CONDA_PREFIX/etc/profile.d/conda.sh
conda activate $ENVNAME
if [ $CONDA_DEFAULT_ENV != $ENVNAME ]; then
	print_alert "activating the new environment failed!"
	exit 1
else
	print_infos "Active conda interpreter $(which conda)"
fi

print_title "setting up channels"
conda config --env --add channels conda-forge
conda config --env --add channels pytorch
conda config --env --add channels nvidia
conda config --env --remove channels defaults
conda config --env --show channels
conda config --env --set channel_priority strict
conda config --env --show channel_priority
conda config --env --set pip_interop_enabled True


print_title "Created Environment"
conda config --show pkgs_dirs >> $CONDA_PREFIX/.condarc # fix wrong pkg cache in mamba
# add pinned packages
cp pinned $CONDA_PREFIX/conda-meta/pinned
print_infos "Added Pinned Packages in $CONDA_PREFIX/conda-meta/pinned"
echo $(cat $CONDA_PREFIX/conda-meta/pinned)
sleep 1
conda info

if !(bool_promt "Use mamba for faster dependency resolving?"); then
	CONDA=mamba
fi

print_title "Installing Packages"
print_alert "NOTE: There may be no progress-bar for CUDATOOLKIT"
$CONDA env update -f $FILE
$CONDA update $ARGS --all
$CONDA update $ARGS --all
conda update $ARGS --all $PINNED
conda update $ARGS --all $PINNED

if !(bool_promt "Install CUDA-compatible JAX?" $CUDA_JAX); then
	# Following installtion instructions from https://github.com/google/jax
	# Force installation of pip-packages for jax and jaxlib (overwrite conda provided jax)
	# pip install --cache-dir $PIP_CACHE_DIR --upgrade "jax[cuda111]" \
	# 	--force-reinstall --no-deps -f https://storage.googleapis.com/jax-releases/jax_releases.html
	# Install any missing dependencies
	pip install --cache-dir $PIP_CACHE_DIR --upgrade "jax[cuda111]"\
		-f https://storage.googleapis.com/jax-releases/jax_releases.html
fi

if !(bool_promt "Install CUDA-compatible MxNet?" $CUDA_MX); then
	# $CONDA install $ARGS --file "requirements/requirements-conda-tensorflow==2.6.0.txt"
	pip install --cache-dir $PIP_CACHE_DIR --upgrade mxnet-cu110==2.0.0a0
fi

# print_alert "Note: Current TensorFlow 2.6 not compatible with numpy 1.21"
if !(bool_promt "Install CUDA-compatible TensorFlow?" $CUDA_TF); then
	# $CONDA install $ARGS --file "requirements/requirements-conda-tensorflow==2.6.0.txt"
	pip install --cache-dir $PIP_CACHE_DIR --upgrade tensorflow
	pip install --cache-dir $PIP_CACHE_DIR --upgrade tensorflow-datasets tensorflow-probability \
	tensorflow-estimator tensorflow-metadata 
fi

if !(bool_promt "Perform post-install update-check?"); then
	$CONDA update $ARGS --all

	if [ $CONDA == "mamba" ]; then
		print_infos "Performing second update run with conda since mamba was used"
		print_infos "This makes sure --strict-channel-priority is abided by"
		conda update $ARGS --all $PINNED
		conda update $ARGS --all $PINNED
	fi
fi

if !(bool_promt "Perform post-install CUDA test?"); then
	echo "which python? > $(which python)"
	python test/test_cuda.py
fi

print_title "ALL DONE"
print_infos "Always use the environment specific conda interpreter!"
print_infos 'Use `conda-develop .` instead of `pip install -e .`!'
