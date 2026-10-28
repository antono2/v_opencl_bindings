"""Keep doc-only input updates quiet without hiding C ABI or generator failures."""
from pathlib import Path
import subprocess
import tempfile
import unittest
from check_input_payload import should_propose


class InputPayloadTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.headers = self.root / 'headers'
        for repo in [self.root, self.headers]:
            repo.mkdir(exist_ok=True)
            self.git(repo, 'init', '-q')
        (self.root / 'src').mkdir()
        (self.root / 'src/opencl.v').write_text('generated binding\n')
        self.commit(self.root, 'src')
        (self.headers / 'CL').mkdir()
        (self.headers / 'CL/cl.h').write_text('C API\n')
        self.commit(self.headers, 'CL')
        self.previous = self.git(self.headers, 'rev-parse', 'HEAD')

    def git(self, repo, *args):
        return subprocess.check_output(['git', '-C', str(repo), *args],
                                       text=True, stderr=subprocess.PIPE).strip()

    def commit(self, repo, path):
        self.git(repo, 'add', path)
        self.git(repo, '-c', 'user.name=Fixture', '-c',
                 'user.email=fixture@example.invalid', 'commit', '-qm', 'fixture')

    def check(self, outcome='success'):
        return should_propose(self.root, self.headers, self.previous, outcome)

    def test_identical_output_is_quiet(self):
        self.assertFalse(self.check())

    def test_upstream_docs_only_revision_is_quiet(self):
        (self.headers / 'README.md').write_text('upstream documentation change\n')
        self.commit(self.headers, 'README.md')
        self.assertNotEqual(self.previous, self.git(self.headers, 'rev-parse', 'HEAD'))
        self.assertFalse(self.check())

    def test_changed_generated_api_is_proposed(self):
        (self.root / 'src/opencl.v').write_text('changed binding\n')
        self.assertTrue(self.check())

    def test_changed_c_header_is_proposed(self):
        (self.headers / 'CL/cl.h').write_text('changed C API or portability fix\n')
        self.commit(self.headers, 'CL')
        self.assertTrue(self.check())

    def test_generation_failure_is_not_hidden(self):
        self.assertTrue(self.check('failure'))

    def test_missing_old_header_revision_is_an_error(self):
        with self.assertRaises(subprocess.CalledProcessError):
            should_propose(self.root, self.headers, 'missing', 'success')


if __name__ == '__main__':
    unittest.main()
