#!/usr/bin/env python3
"""Copy the canonical module sources into an antono2/opencl checkout."""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess


ROOT = Path(__file__).resolve().parent.parent

SOURCE_FILES = {
    "src/opencl.v": "opencl.v",
    "src/convenience.v": "convenience.v",
    "src/ownership.v": "ownership.v",
    "src/program.v": "program.v",
    "src/event.v": "event.v",
    "src/capabilities.v": "capabilities.v",
    "src/external_interop.v": "external_interop.v",
    "test/convenience_test.v": "convenience_test.v",
    "test/pointer_abi_test.v": "test/pointer_abi_test.v",
    "test/pointer_abi_shim.c": "test/pointer_abi_shim.c",
    "API_DESIGN.md": "API_DESIGN.md",
    "OWNERSHIP.md": "OWNERSHIP.md",
    "REGISTRY_COMMIT": "REGISTRY_COMMIT",
    "HEADERS_COMMIT": "HEADERS_COMMIT",
}


def tracked_distribution_files() -> dict[str, str]:
    output = subprocess.check_output(
        ["git", "-C", str(ROOT), "ls-files", "-z", "abi", "examples", "include"]
    )
    paths = output.decode().rstrip("\0").split("\0") if output else []
    return {path: path for path in paths}


def validate_target(target: Path) -> None:
    module_file = target / "v.mod"
    if not module_file.is_file() or "name: 'antono2.opencl'" not in module_file.read_text():
        raise SystemExit(f"not an antono2.opencl checkout: {target}")


def sync(target: Path, *, check: bool) -> int:
    validate_target(target)
    mappings = SOURCE_FILES | tracked_distribution_files()
    changed = []
    for source_name, target_name in sorted(mappings.items()):
        source = ROOT / source_name
        destination = target / target_name
        source_bytes = source.read_bytes()
        if destination.is_file() and destination.read_bytes() == source_bytes:
            continue
        changed.append(target_name)
        if not check:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
    if changed:
        print("published module differs:")
        for path in changed:
            print(f"  {path}")
        return 1 if check else 0
    print("published module is synchronized")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("target", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    raise SystemExit(sync(args.target.resolve(), check=args.check))


if __name__ == "__main__":
    main()
