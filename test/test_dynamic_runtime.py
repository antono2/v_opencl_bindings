#!/usr/bin/env python3
"""Prove a dynamic executable starts without OpenCL and diagnoses a missing loader."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--v', default='v')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as temporary:
    binary = Path(temporary) / ('first.exe' if os.name == 'nt' else 'first')
    subprocess.run([args.v, '-d', 'opencl_dynamic', '-o', str(binary), str(root / 'examples/getting_started')], check=True)
    env = dict(os.environ, OPENCL_LIBRARY=str(Path(temporary) / 'missing-opencl-runtime'))
    failed = subprocess.run([str(binary)], env=env, capture_output=True, text=True)
    assert failed.returncode != 0
    assert 'OpenCL runtime unavailable' in failed.stderr, failed.stdout + failed.stderr
    if sys.platform == 'linux':
        linked = subprocess.check_output(['ldd', str(binary)], text=True)
        assert 'libOpenCL' not in linked, linked
print('Missing-runtime behavior verified.')
