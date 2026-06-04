"""Write the new semantic-release version into the VERSION file."""

import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: bump_version.py <new_version>", file=sys.stderr)
        return 1

    new_version = sys.argv[1].strip()
    version_file = Path(__file__).resolve().parent.parent / "VERSION"
    version_file.write_text(f"{new_version}\n", encoding="utf-8")
    print(f"VERSION updated to {new_version}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
