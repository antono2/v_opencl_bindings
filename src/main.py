#!/usr/bin/env python3
"""Generate the public V OpenCL module from the Khronos XML registry."""

from __future__ import annotations

import argparse
from pathlib import Path

from opencl_generator import OpenCLGenerator


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("-registry", default="opencldocs/xml/cl.xml")
    parser.add_argument("target", nargs="?", default="opencl.v", choices=["opencl.v"])
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    registry = Path(args.registry)
    if not registry.is_absolute():
        registry = root / registry
    output = root / "src" / args.target
    OpenCLGenerator(registry).write(output)


if __name__ == "__main__":
    main()

