import sys
from importlib import metadata

def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("Usage: verify_version.py <distribution-name> <expected-version>", file=sys.stderr)
        return 64
    name, expected = argv[1], argv[2]
    try:
        installed = metadata.version(name)
    except metadata.PackageNotFoundError:
        print(f"Distribution {name} not found in current environment", file=sys.stderr)
        return 2
    print(f"Installed {name} {installed}. Expected {expected}")
    return 0 if installed == expected else 3

if __name__ == "__main__":
    sys.exit(main(sys.argv))