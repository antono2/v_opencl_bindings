#!/usr/bin/env python3
"""Assemble an isolated test module using the same manifest as publication."""
from pathlib import Path
import sys
from sync_published_module import sync
root = Path(__file__).resolve().parents[1]
target = Path(sys.argv[1]).resolve()
target.mkdir(parents=True, exist_ok=True)
if not (target / 'v.mod').exists():
    version = (root / 'VERSION').read_text().strip()
    (target / 'v.mod').write_text("Module {\n name: 'antono2.opencl'\n version: '" + version + "'\n}\n")
raise SystemExit(sync(target, check=False))
