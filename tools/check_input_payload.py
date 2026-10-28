"""Ignore upstream revision churn unless generated bindings or C headers changed."""
import argparse
from pathlib import Path
import subprocess


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()


def should_propose(root, headers, previous_headers, outcome):
    # Failed generation is actionable, even if it produced no output to diff.
    if outcome == 'failure':
        return True
    if outcome != 'success':
        raise ValueError('Generation must have completed before proposing inputs')
    result = subprocess.run(['git', '-C', str(root), 'diff', '--quiet', 'HEAD',
                             '--', 'src/opencl.v'])
    if result.returncode == 1:
        return True
    result.check_returncode()
    # C header changes still deserve review, including portability/ABI fixes.
    # Changes confined to upstream docs/metadata do not advance the pin alone.
    return git(headers, 'rev-parse', previous_headers + ':CL') != git(headers, 'rev-parse', 'HEAD:CL')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--previous-headers', required=True)
    parser.add_argument('--generation-outcome', choices=['success', 'failure'], required=True)
    parser.add_argument('--headers', type=Path, default=Path('openclheaders'))
    args = parser.parse_args()
    print('true' if should_propose(Path.cwd(), args.headers,
                                  args.previous_headers, args.generation_outcome) else 'false')
