# noqa: INP001
"""Small script to verify the installed version of a distribution."""

import logging
import sys
from importlib import metadata

logger = logging.getLogger(__name__)


def main(argv: list[str]) -> int:
    """Verify the installed version of a distribution.

    Parameters
    ----------
    argv : list[str]
        Command line arguments.
        Expects two arguments: the distribution name and the expected version.

    Returns
    -------
    int
        Exit code: 0 if the installed version matches the expected version,
        2 if the distribution is not found, 3 if the versions do not match,
        64 for incorrect usage.
    """
    if len(argv) != 3:  # noqa: PLR2004
        logger.error("Usage: verify_version.py <distribution-name> <expected-version>")
        return 64
    name, expected = argv[1], argv[2]
    try:
        installed = metadata.version(name)
    except metadata.PackageNotFoundError:
        logger.exception("Distribution %s not found in current environment", name)
        return 2
    logger.info("Installed %s %s. Expected %s", name, installed, expected)
    return 0 if installed == expected else 3


if __name__ == "__main__":
    sys.exit(main(sys.argv))
