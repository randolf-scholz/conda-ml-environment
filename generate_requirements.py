#!/usr/bin/env python3
r"""System utilities.

Contains things like

- user queries (yes/no/choice questions)
- package installation
"""

from __future__ import annotations

import importlib
import logging
import multiprocessing as mp
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Final, Iterable, Optional

import yaml

logger = logging.getLogger(__name__)
__all__: Final[list[str]] = [
    "query_bool",
    "query_choice",
    "get_requirements",
    "install_package",
    "write_requirements",
]


def info_message(s: str) -> str:
    """Bold Red"""
    GREEN = "\033[92m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"
    return BOLD + UNDERLINE + GREEN + s + ENDC


def error_message(s: str) -> str:
    """Bold Red"""
    RED = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"
    return BOLD + UNDERLINE + RED + s + ENDC


def query_bool(question: str, default: Optional[bool] = True) -> bool:
    """Ask a yes/no question and returns answer as bool.

    Parameters
    ----------
    question: str
    default: Optional[bool] (default=True)

    Returns
    -------
    bool
    """
    responses = {
        "y": True,
        "yes": True,
        "n": False,
        "no": False,
    }

    prompt = "([y]/n)" if default else "([n]/y)"

    while True:
        try:
            print(question)
            choice = input(prompt).lower()
        except KeyboardInterrupt:
            print("Operation aborted. Exiting.")
            sys.exit(0)

        if not choice and default is not None:
            return default
        if choice in responses:
            return responses[choice]
        print("Please enter either of %s", responses)


def query_choice(
    question: str,
    choices: set[str],
    default: Optional[str] = None,
    number_choice: bool = True,
) -> str:
    r"""Ask the user to pick a choice.

    Parameters
    ----------
    question: str
    choices: tuple[str]
    default: Optional[str]
    number_choice: bool (default=True)

    Returns
    -------
    str
    """
    choices = set(choices)
    ids: dict[int, str] = dict(enumerate(choices))

    if default is not None:
        assert default in choices

    options = "\n".join(
        f"{k}. {v}" + " (default)" * (v == default) for k, v in enumerate(choices)
    )

    while True:
        try:
            print(question)
            print(options)
            choice = input("Your choice (int or name)")
        except KeyboardInterrupt:
            print("Operation aborted. Exiting.")
            sys.exit(0)

        if choice in choices:
            return choice
        if number_choice and choice.isdigit() and int(choice) in ids:
            return ids[int(choice)]
        print("Please enter either of %s", choices)


def install_package(
    package: str,
    version: Optional[str] = None,
    non_interactive: bool = False,
    installer: str = "pip",
    options: tuple[str, ...] = (),
):
    r"""Install a package via pip or other package manger.

    Parameters
    ----------
    package: str
    non_interactive: bool (default=False)
        If false, will generate a user prompt.
    installer: str (default='pip')
        Can also use `conda` or `mamba`
    options: tuple[str, ...]
        Options to pass to the isntaller
    """
    package_available = importlib.util.find_spec(package)
    install_call = (installer, "install", package + "=={version}" * bool(version))
    if not package_available:
        if non_interactive or query_bool(
            f"Package '{package}' not found. Do you want to install it?"
        ):
            try:
                subprocess.run(install_call + options, check=True)
            except subprocess.CalledProcessError as E:
                print(
                    error_message(f"Package {package}=={version} failed with error {E}")
                )
                sys.exit(1)
    else:
        logger.info("Package '%s' already installed.", package)


def get_requirements(package: str, version: Optional[str] = None) -> dict[str, str]:
    r"""Return dictionary containing requirements with version numbers.

    Parameters
    ----------
    package: str
    version: Optional[str] (default=None)
        In the case of None, the latest version is used.

    Returns
    -------
    dict[str, str]
    """
    version = None if version in ("latest", "newest") else version
    # get requirements as string of the form package==version\n.
    try:
        reqs = subprocess.check_output(
            (
                r"johnnydep",
                f"{package}" + f"=={version}" * bool(version),
                r"--output-format",
                r"pinned",
            ),
            text=True,
            encoding="utf8",
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError as E:
        print(error_message(f"Package {package}=={version} failed with error {E}"))
        sys.exit(1)

    return dict(line.split("==") for line in reqs.rstrip("\n").split("\n"))


def write_requirements(
    package: str, version: Optional[str] = None, path: Optional[Path] = None
):
    r"""Write a requirements dictionary to a requirements.txt file.

    Parameters
    ----------
    package: str
    version: Optional[str] (default=None)
        In the case of None, the latest version is used.
    path: Optional[Path] (default='requirements')
    """
    print(info_message(f"Generating requirements for {package}=={version}"))
    version = None if version in ("latest", "newest") else version
    requirements: dict[str, str] = get_requirements(package, version)
    # Note: the first entry is the package itself!
    fname = f"requirements-{package}=={requirements.pop(package)}.txt"
    path = Path("requirements") if path is None else Path(path)
    path.mkdir(exist_ok=True)

    with open(path.joinpath(fname), "w", encoding="utf8") as file:
        file.write("\n".join(f"{k}=={requirements[k]}" for k in sorted(requirements)))

    print(info_message(f"Created {fname}"))


def flatten_dict(
    d: dict[Any, Iterable[Any]], recursive: bool = True
) -> list[tuple[Any, ...]]:
    r"""Flatten a dictionary containing iterables to a list of tuples.

    Parameters
    ----------
    d: dict
    recursive: bool (default=True)
        If true applies flattening strategy recursively on nested dicts, yielding
        list[tuple[key1, key2, ...., keyN, value]]

    Returns
    -------
    list[tuple[Any, ...]]
    """
    result = []
    for key, iterable in d.items():
        for item in iterable:
            if isinstance(item, dict) and recursive:
                gen: list[tuple[Any, ...]] = flatten_dict(item, recursive=True)
                result += [(key,) + tup for tup in gen]
            else:
                result += [(key, item)]
    return result


if __name__ == "__main__":
    info_message(f"Running on {sys.version}")
    with open("required.yaml", "r", encoding="utf8") as file:
        data = yaml.safe_load(file)

    with mp.Pool() as pool:
        pool.starmap(write_requirements, flatten_dict(data))

    info_message("ALL DONE")
