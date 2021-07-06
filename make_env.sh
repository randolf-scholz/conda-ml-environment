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
PIP_CACHE_DIR=""

usage="
	$(basename "$0") [-c --cache] [-f --file] [-h --help] [-m --mamba] [-y --yes] envname
	Compile tutorials matching 'tutorial<id>.tex'
	envname    : name of the environment to initialize
	-c --cache : specify PIP cache directory (default: check if ~/.cache/pip exists)
	-f --file  : path to the environment file (default=env.yaml)
	-h --help  : print this help
	-m --mamba : use mamba for installing packages (faster&better dependecy solving)
	-y --yes   : passes -y flag to all options (default=off)
	"

print_title () { echo -e "\n\e[32m>>> $1 <<<\e[0m"; }
print_alert () { echo -e   "\e[31m>>> $1 <<<\e[0m"; }
print_infos () { echo -e "\e[33m$1\e[0m" ; }

bool_promt () {
	# If non-interactive, return true, else ask user (y/n)
	print_title "$1"

	if $NON_INTERACTIVE; then 
		echo -e "Proceed ([y]/n)? \e[33m>>> YES\e[0m\n"
		sleep 3
		return 1
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

for key in "$@"; do
case $key in
	-c|--cache)
	PIP_CACHE_DIR=$key
	shift # past argument with no value
	;;
	-f|--file)
	FILE=$key
	shift # past argument with no value
	;;
	-h|--help)
	echo "$usage" >&2
	exit
	;;
	-m|--mamba)
	CONDA=mamba
	shift # past argument with no value
	;;
	-y|--non-interactive)
	NON_INTERACTIVE=true
	shift # past argument with no value
	;;
	-*|--*)
	echo "illegal option $key"
	echo "$usage"
	exit 1
	;;
esac
done

remaining_args=("$@")
if [ "$remaining_args" == "" ]; then
	# if no positional was given ask user for environment name
    echo "Enter the enviroment name"
	read ENVNAME
else
	ENVNAME="$remaining_args"
fi

if $NON_INTERACTIVE; then
	ARGS="-y"
else
	ARGS=""
fi

if [ "$PIP_CACHE_DIR" == "" ]; then
	if [ -d "$HOME/.cache/pip" ]; then
		PIP_CACHE_DIR="$HOME/.cache/pip"
		print_infos "Found existing pip cache directory in $PIP_CACHE_DIR"
	fi
fi

########
# MAIN #
########

print_infos "Creating conda environemnt      : $ENVNAME"
print_infos "Caching PIP packages in         : $PIP_CACHE_DIR"
print_infos "Running in non-interactive mode : $NON_INTERACTIVE"
print_infos "Using environment file          : $FILE"
print_infos "Installing packages via         : $CONDA"
sleep 3

conda create $ARGS --name $ENVNAME -c conda-forge mamba
source activate $ENV

print_title "setting up channels"
conda config --env --add channels conda-forge
conda config --env --add channels pytorch
conda config --env --add channels nvidia
conda config --env --remove channels defaults
conda config --env --show channels
conda config --env --set channel_priority strict
conda config --env --show channel_priority

print_title "Created Environment"
conda config --show pkgs_dirs >> $CONDA_PREFIX/.condarc # fix wrong pkg cache in mamba
conda info

if !(bool_promt "Use mamba for faster dependency resolving?"); then
	CONDA=mamba
fi

print_title "Installing Packages"
print_alert "NOTE: There will be no progress-bar for CUDATOOLKIT"
$CONDA env update -f $FILE

if !(bool_promt "Install TensorFlow 2.5?"); then
	# install depencies in TF 2.5 compatible version,
	# this avoids taht these packages get overwritten by pip.
	$CONDA install $ARGS astunparse=1.6.3 gast=0.4 google-pasta=0.2 grpcio=1.34.1 h5py=3.1 numpy=1.19
	pip install --cache-dir $PIP_CACHE_DIR tensorflow==2.5 tensorflow-gpu==2.5
fi

if !(bool_promt "Install CUDA-compatible JAX?"); then
	# Following installtion instructions from https://github.com/google/jax
	pip install --cache-dir $PIP_CACHE_DIR --upgrade "jax[cuda111]" -f https://storage.googleapis.com/jax-releases/jax_releases.html
	pip install --cache-dir $PIP_CACHE_DIR --upgrade flax optax
fi

if !(bool_promt "Perform post-install update-check?"); then
	$CONDA update $ARGS --all

	if [ $CONDA == "mamba" ]; then
		print_infos "Performing second update run with conda since mamba was used"
		print_infos "This makes sure --strict-channel-priority is abdided by"
		conda update $ARGS --all
	fi
fi

if !(bool_promt "Perform post-install CUDA test?"); then
	echo "which python? > $(which python)"
	python test/test_cuda.py
fi

print_title "ALL DONE"
