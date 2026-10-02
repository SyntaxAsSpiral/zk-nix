"""Decision tests for zcli context assemble/sync/deploy. Python and SSH are fakes."""

import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("zcli-context.sh")


class ContextTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="zcli-context.")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        workshop = self.root / "workshop" / "src"
        workshop.mkdir(parents=True)
        (workshop / "sync.py").write_text("print('sync')\n")
        (workshop / "assemble.py").write_text("print('assemble')\n")
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        self.write_bin("python", """#!/bin/sh
printf '%s\\n' "$@" >> "$PY_LOG"
echo python >> "$TRACE"
exit 0
""")
        self.write_bin("ssh", """#!/bin/sh
printf '%s\\n' "$@" >> "$SSH_LOG"
echo ssh >> "$TRACE"
exit 0
""")
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "ZCLI_CONTEXT_HOST": "adeck",
            "ZCLI_CONTEXT_ROOT": str(self.root),
            "ZCLI_CONTEXT_PYTHON": str(bin_dir / "python"),
            "PY_LOG": str(self.root / "python.log"),
            "SSH_LOG": str(self.root / "ssh.log"),
            "TRACE": str(self.root / "trace"),
        }

    def write_bin(self, name, text):
        path = self.root / "bin" / name
        path.write_text(text)
        path.chmod(path.stat().st_mode | stat.S_IEXEC)

    def invoke(self, *args, host="adeck", expected=0):
        result = subprocess.run(
            ["bash", str(SCRIPT), *args],
            cwd=self.root,
            env={**self.env, "ZCLI_CONTEXT_HOST": host},
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def trace(self):
        path = self.root / "trace"
        return path.read_text().splitlines() if path.exists() else []

    def python_log(self):
        path = self.root / "python.log"
        return path.read_text() if path.exists() else ""

    def test_sync_deploys_without_git(self):
        result = self.invoke("sync")
        self.assertIn("CONTEXT·SYNC·INITIATED", result.stdout)
        log = self.python_log()
        self.assertIn("sync.py", log)
        self.assertIn("--no-git", log)
        self.assertEqual(self.trace(), ["python"])
        self.assertFalse((self.root / "ssh.log").exists())

    def test_deploy_runs_full_sync_with_commit_and_push(self):
        result = self.invoke("deploy", "--dry-run")
        self.assertIn("CONTEXT·DEPLOY·INITIATED", result.stdout)
        log = self.python_log()
        self.assertIn(str(self.root / "workshop" / "src" / "sync.py"), log)
        self.assertIn("--dry-run", log)
        self.assertNotIn("--no-git", log)
        self.assertNotIn("assemble.py", log)
        self.assertEqual(self.trace(), ["python"])

    def test_deploy_from_another_host_asks_adeck(self):
        self.invoke("deploy", "--verbose", host="nxiz")
        ssh = (self.root / "ssh.log").read_text()
        self.assertIn("zk@100.89.32.9", ssh)
        self.assertIn("/etc/profiles/per-user/zk/bin/zcli", ssh)
        self.assertIn("deploy\ncontext\n--verbose", ssh)
        self.assertEqual(self.python_log(), "")
        self.assertEqual(self.trace(), ["ssh"])
