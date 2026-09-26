"""Local integration tests; every destination and SSH command is isolated."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("zcli-sync.sh")


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="zcli-test.")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / "source"
        self.dest = self.root / "dest"
        self.source.mkdir()
        self.git(self.source, "init", "-q")
        (self.source / ".gitignore").write_text("/secrets/\n/ignored\n")
        (self.source / "flake.nix").write_text("original\n")
        (self.source / "removed").write_text("old\n")
        self.git(self.source, "add", ".")
        self.git(self.source, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-qm", "initial")
        self.git(self.root, "clone", "-q", str(self.source), str(self.dest))
        for repo in (self.source, self.dest):
            (repo / "secrets").mkdir()
            (repo / "secrets" / "token").write_text(repo.name)
        self.script = self.root / "sync.sh"
        self.script.write_text(
            SCRIPT.read_text()
            .replace("SOURCE=/mnt/echo/nix-os", f"SOURCE={self.source}")
            .replace("DEST=/etc/nixos", f"DEST={self.dest}")
            .replace("HOST=$(hostname)", 'HOST=${TEST_HOST:-adeck}')
            .replace("/run/lock/zcli-sync-secrets.lock", str(self.root / "secrets.lock"))
        )
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        ssh = bin_dir / "ssh"
        ssh.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$SSH_LOG"\nexit "${SSH_STATUS:-255}"\n')
        ssh.chmod(0o755)
        sudo = bin_dir / "sudo"
        sudo.write_text('#!/bin/sh\nshift\nexec "$@"\n')
        sudo.chmod(0o755)
        self.env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}",
                    "SSH_LOG": str(self.root / "ssh.log")}

    def git(self, repo, *args):
        return subprocess.check_output(["git", "-C", str(repo), *args], stderr=subprocess.PIPE).decode().strip()

    def run_sync(self, *args, host="adeck", expected=0, **env):
        result = subprocess.run(["bash", str(self.script), *args],
                                env={**self.env, "TEST_HOST": host, **env},
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def test_publish_index_and_secrets_without_touching_source_git(self):
        (self.source / "flake.nix").write_text("edited\n")
        (self.source / "new file\nwith newline").write_text("new\n")
        (self.source / "removed").unlink()
        (self.source / "ignored").write_text("private\n")
        self.git(self.source, "add", "-A")
        (self.source / "flake.nix").write_text("unstaged edit\n")
        (self.source / "untracked").write_text("local only\n")
        (self.dest / "local-new").write_text("keep me\n")
        (self.dest / "ignored").write_text("keep me too\n")
        before = (self.source / ".git/index").read_bytes()
        objects = sorted(p.relative_to(self.source) for p in (self.source / ".git/objects").rglob("*"))
        head = self.git(self.dest, "rev-parse", "HEAD")
        self.run_sync()
        self.assertEqual((self.dest / "flake.nix").read_text(), "edited\n")
        self.assertTrue((self.dest / "new file\nwith newline").exists())
        self.assertFalse((self.dest / "removed").exists())
        self.assertEqual((self.dest / "ignored").read_text(), "keep me too\n")
        self.assertEqual((self.dest / "local-new").read_text(), "keep me\n")
        self.assertFalse((self.dest / "untracked").exists())
        self.assertEqual((self.dest / "secrets/token").read_text(), "source")
        self.assertEqual(self.git(self.dest, "rev-parse", "HEAD"), head)
        self.assertEqual((self.source / ".git/index").read_bytes(), before)
        self.assertEqual(sorted(p.relative_to(self.source) for p in (self.source / ".git/objects").rglob("*")), objects)
        self.run_sync()
        (self.source / "new file\nwith newline").unlink()
        self.git(self.source, "add", "--", "new file\nwith newline")
        self.run_sync()
        self.assertFalse((self.dest / "new file\nwith newline").exists())
        self.assertTrue((self.dest / ".git/zcli-sync-receipt").exists())

    def test_clean_commit_is_clean_on_the_destination(self):
        (self.source / "flake.nix").write_text("committed\n")
        self.git(self.source, "add", "flake.nix")
        self.git(self.source, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-qm", "second")
        self.run_sync()
        self.assertEqual(self.git(self.dest, "rev-parse", "HEAD"),
                         self.git(self.source, "rev-parse", "HEAD"))
        self.assertEqual(self.git(self.dest, "status", "--porcelain"), "")
        self.assertEqual((self.dest / "flake.nix").read_text(), "committed\n")

    def test_staged_changes_stay_staged(self):
        (self.source / "flake.nix").write_text("staged\n")
        self.git(self.source, "add", "flake.nix")
        head = self.git(self.source, "rev-parse", "HEAD")
        self.run_sync()
        self.assertEqual(self.git(self.dest, "rev-parse", "HEAD"), head)
        self.assertIn("M  flake.nix", self.git(self.dest, "status", "--porcelain"))
        self.assertEqual((self.dest / "flake.nix").read_text(), "staged\n")

    def test_preview_preserves_destination_files_index_and_refs(self):
        (self.source / "flake.nix").write_text("edited\n")
        self.git(self.source, "add", "flake.nix")
        before = (self.dest / ".git/index").read_bytes()
        self.run_sync("--dry")
        self.assertEqual((self.dest / "flake.nix").read_text(), "original\n")
        self.assertEqual((self.dest / ".git/index").read_bytes(), before)
        self.assertFalse((self.dest / ".git/zcli-sync-receipt").exists())
        self.assertFalse((self.dest / ".git/refs/zcli/sync").exists())

    def test_destination_worktree_and_staged_edits_are_replaced(self):
        (self.dest / "flake.nix").write_text("local work\n")
        result = self.run_sync()
        self.assertIn("replaced: flake.nix", result.stdout)
        self.assertEqual((self.dest / "flake.nix").read_text(), "original\n")
        (self.dest / "flake.nix").write_text("local work\n")
        self.git(self.dest, "add", "flake.nix")
        (self.dest / "flake.nix").write_text("original\n")
        result = self.run_sync()
        self.assertIn("replaced: flake.nix", result.stdout)
        self.assertEqual(self.git(self.dest, "show", ":flake.nix"), "original")

    def test_ignored_destination_collision_is_replaced(self):
        (self.dest / "ignored").write_text("keep me\n")
        (self.source / "ignored").write_text("incoming\n")
        self.git(self.source, "add", "-f", "ignored")
        result = self.run_sync()
        self.assertIn("replaced: ignored", result.stdout)
        self.assertEqual((self.dest / "ignored").read_text(), "incoming\n")

    def test_remote_invocation_forwards_original_default_and_validates_targets(self):
        self.run_sync("--dry", host="nxiz", SSH_STATUS="0")
        args = (self.root / "ssh.log").read_text().splitlines()
        self.assertEqual(args[-4:], ["/etc/profiles/per-user/zk/bin/zcli", "sync", "nxiz", "--dry"])
        self.run_sync("bad-host", host="nxiz", expected=1)
        self.run_sync("all", host="zrrh", SSH_STATUS="0")
        self.assertEqual((self.root / "ssh.log").read_text().splitlines()[-4:], ["adeck", "nxiz", "zrrh", "tm20"])

    def test_unreachable_target_does_not_prevent_local_sync(self):
        (self.source / "flake.nix").write_text("edited\n")
        self.git(self.source, "add", "flake.nix")
        self.run_sync("nxiz", "adeck", expected=1)
        self.assertEqual((self.dest / "flake.nix").read_text(), "edited\n")

    def test_tm20_receiver_only_copies_secrets_preserving_modes_and_extra_files(self):
        for dry in (True, False):
            stage = Path(tempfile.mkdtemp(prefix="zcli-sync."))
            self.addCleanup(lambda p=stage: shutil.rmtree(p, ignore_errors=True))
            (stage / "payload").mkdir()
            token = stage / "payload/print-token"
            token.write_text("test credential\n")
            token.chmod(0o600)
            self.run_sync("--receive", str(stage), "secrets", "a" * 40, "b" * 40,
                          str(dry).lower(), host="tm20")
            self.assertEqual((self.dest / "secrets/print-token").exists(), not dry)
            self.assertEqual((self.dest / "secrets/token").read_text(), "dest")
            self.assertEqual((self.dest / "flake.nix").read_text(), "original\n")
        self.assertEqual((self.dest / "secrets/print-token").stat().st_mode & 0o777, 0o600)

    def test_lock_and_interrupted_snapshot_block_mutation(self):
        import fcntl
        with (self.dest / ".git/zcli.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertIn("another sync/build/deploy", self.run_sync(expected=1).stderr)
        (self.dest / ".git/zcli-sync-incomplete").write_text("f" * 40 + "\n")
        self.assertIn("interrupted sync", self.run_sync(expected=1).stderr)
        self.assertEqual((self.dest / "flake.nix").read_text(), "original\n")


if __name__ == "__main__":
    unittest.main()
