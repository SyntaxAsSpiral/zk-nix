"""Decision tests for zcli build/deploy/wake. SSH, nh, and wake are fakes."""

import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("zcli-run.sh")


class RunTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="zcli-run.")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.script = self.root / "zcli-run.sh"
        self.script.write_text(SCRIPT.read_text().replace(
            "HOST=$(hostname)", 'HOST=${TEST_HOST:-adeck}'))
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        self.write_bin("ssh", """#!/bin/sh
printf '%s\\n' "$@" >> "$SSH_LOG"
joined=$(printf '%s ' "$@")
if printf '%s' "$joined" | grep -q 'store info'; then
  echo ready >> "$TRACE"
  n=0
  [ -f "$READY_COUNT" ] && n=$(cat "$READY_COUNT")
  n=$((n + 1))
  echo "$n" > "$READY_COUNT"
  [ "$n" -ge "${READY_AFTER:-1}" ]
  exit
fi
if printf '%s' "$joined" | grep -q 'systemd-run'; then
  echo reboot >> "$TRACE"
  exit 0
fi
if printf '%s' "$joined" | grep -q ' os '; then
  echo nh >> "$TRACE"
  exit 0
fi
if printf '%s' "$joined" | grep -q readlink; then
  echo /nix/store/fake-sd-image
  exit 0
fi
exit 0
""")
        self.write_bin("sudo", """#!/bin/sh
printf '%s\\n' "$@" >> "$SUDO_LOG"
while [ "$1" = "-n" ]; do shift; done
exec "$@"
""")
        self.write_bin("systemd-run", """#!/bin/sh
printf '%s\\n' "$@" >> "$REBOOT_LOG"
echo reboot >> "$TRACE"
exit 0
""")
        self.write_bin("wakeonlan", """#!/bin/sh
printf '%s\\n' "$@" >> "$WAKE_LOG"
exit 0
""")
        self.write_bin("zcli-sync", """#!/bin/sh
printf '%s\\n' "$@" >> "$SYNC_LOG"
echo sync >> "$TRACE"
exit 0
""")
        self.write_bin("nh", """#!/bin/sh
printf '%s\\n' "$@" >> "$NH_LOG"
echo nh >> "$TRACE"
exit 0
""")
        self.write_bin("systemd-inhibit", """#!/bin/sh
printf '%s\\n' "$@" >> "$INHIBIT_LOG"
while [ $# -gt 0 ]; do
  case "$1" in
    --what|--who|--why|--mode) shift 2 ;;
    --what=*|--who=*|--why=*|--mode=*) shift ;;
    *) break ;;
  esac
done
exec "$@"
""")
        self.write_bin("nix", """#!/bin/sh
printf '%s\\n' "$@" >> "$NIX_LOG"
exit 0
""")
        self.write_bin("date", "#!/bin/sh\necho 1000\n")
        self.env = {
            **os.environ,
            "PATH": f"{bin_dir}:{os.environ['PATH']}",
            "TEST_HOST": "adeck",
            "ZCLI_NH": str(bin_dir / "nh"),
            "ZCLI_INHIBIT": str(bin_dir / "systemd-inhibit"),
            "INHIBIT_LOG": str(self.root / "inhibit.log"),
            "ZCLI_NIX": str(bin_dir / "nix"),
            "ZCLI_WAKE": str(bin_dir / "wakeonlan"),
            "ZCLI_SYNC": str(bin_dir / "zcli-sync"),
            "ZCLI_WAKE_INTERVAL": "0",
            "ZCLI_WAKE_DEADLINE": "5",
            "SSH_LOG": str(self.root / "ssh.log"),
            "SUDO_LOG": str(self.root / "sudo.log"),
            "REBOOT_LOG": str(self.root / "reboot.log"),
            "WAKE_LOG": str(self.root / "wake.log"),
            "SYNC_LOG": str(self.root / "sync.log"),
            "NH_LOG": str(self.root / "nh.log"),
            "NIX_LOG": str(self.root / "nix.log"),
            "TRACE": str(self.root / "trace"),
            "READY_COUNT": str(self.root / "ready.count"),
            "READY_AFTER": "1",
            "ZCLI_CANONICAL": str(self.root),
        }

    def write_bin(self, name, text):
        path = self.root / "bin" / name
        path.write_text(text)
        path.chmod(path.stat().st_mode | stat.S_IEXEC)

    def invoke(self, *args, host="adeck", expected=0, **env):
        result = subprocess.run(
            ["bash", str(self.script), *args],
            cwd=self.root,
            env={**self.env, "TEST_HOST": host, **env},
            capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def trace(self):
        path = self.root / "trace"
        return path.read_text().splitlines() if path.exists() else []

    def test_rejects_invalid_deploy_lists_and_flags_before_any_work(self):
        for args in (
            ("build", "all"),
            ("build", "nxiz", "--dry"),
            ("deploy", "nxiz", "--dry"),
            ("deploy", "nxiz", "nxiz"),
            ("deploy", "nxiz", "all"),
            ("build", "nxiz", "--switch"),
            ("image", "nxiz"),
        ):
            result = self.invoke(*args, expected=1)
            self.assertNotIn("reboot scheduled", result.stdout)
        self.assertEqual(self.trace(), [])

    def test_wake_skips_packet_when_zrrh_is_ready(self):
        result = self.invoke("wake")
        self.assertIn("zrrh: already ready", result.stdout)
        self.assertFalse((self.root / "wake.log").exists())

    def test_wake_sends_packet_from_adeck_then_waits(self):
        result = self.invoke("wake", READY_AFTER="2")
        self.assertIn("zrrh: ready", result.stdout)
        self.assertIn("60:cf:84:61:d8:00", (self.root / "wake.log").read_text())
        self.assertIn("192.168.0.255", (self.root / "wake.log").read_text())
        self.assertNotIn("100.89.32.9", (self.root / "ssh.log").read_text())

    def test_wake_from_another_host_asks_adeck_to_send(self):
        self.invoke("wake", host="nxiz", READY_AFTER="2")
        ssh = (self.root / "ssh.log").read_text()
        self.assertIn("100.89.32.9", ssh)
        self.assertIn("60:cf:84:61:d8:00", ssh)
        self.assertFalse((self.root / "wake.log").exists())

    def test_build_syncs_then_runs_nh_on_zrrh_without_deploying(self):
        self.invoke("build", "nxiz")
        self.assertEqual((self.root / "sync.log").read_text().split(), ["zrrh"])
        self.assertEqual(self.trace(), ["ready", "sync", "nh"])
        nh = (self.root / "ssh.log").read_text()
        self.assertIn("os\nbuild\n-H\nnxiz\n", nh)
        self.assertIn("--what=sleep", nh)
        self.assertIn("--mode=block", nh)
        self.assertIn("--why=zcli build nxiz", nh)
        self.assertNotIn("--target-host", nh)
        self.assertFalse((self.root / "reboot.log").exists())

    def test_deploy_boots_schedules_reboot_and_returns(self):
        result = self.invoke("deploy", "nxiz")
        self.assertIn("reboot scheduled on nxiz", result.stdout)
        self.assertEqual(self.trace(), ["ready", "sync", "nh", "reboot"])
        ssh = (self.root / "ssh.log").read_text()
        self.assertIn("boot", ssh)
        self.assertIn("--what=sleep", ssh)
        self.assertIn("--why=zcli deploy nxiz", ssh)
        self.assertIn("sleep\ninfinity", ssh)
        self.assertIn("--target-host", ssh)
        self.assertIn("zk@nxiz", ssh)
        self.assertIn("100.115.135.104", ssh)
        self.assertIn("--on-active=2", ssh)
        self.assertIn("systemctl", ssh)

    def test_deploy_zrrh_has_no_target_host(self):
        self.invoke("deploy", "zrrh")
        ssh = (self.root / "ssh.log").read_text()
        self.assertNotIn("--target-host", ssh)
        self.assertIn("100.77.90.79", ssh)

    def test_deploy_of_the_local_host_reboots_locally(self):
        result = self.invoke("deploy", "adeck")
        self.assertIn("reboot scheduled on adeck", result.stdout)
        self.assertIn("zk@adeck", (self.root / "ssh.log").read_text())
        self.assertTrue((self.root / "reboot.log").exists())
        self.assertNotIn("systemd-run", (self.root / "ssh.log").read_text())

    def test_multi_host_boots_in_user_order_with_command_host_last(self):
        result = self.invoke("deploy", "adeck", "nxiz", "zrrh")
        self.assertIn("Deploy order: nxiz zrrh adeck (boot)", result.stdout)
        self.assertEqual(self.trace(), ["ready", "sync", "nh", "nh", "nh", "reboot", "reboot", "reboot"])
        self.assertLess(result.stdout.index("==> deploy nxiz"), result.stdout.index("==> deploy zrrh"))
        self.assertLess(result.stdout.index("==> deploy zrrh"), result.stdout.index("==> deploy adeck"))
        self.assertLess(result.stdout.index("==> deploy adeck"), result.stdout.index("reboot scheduled on nxiz"))
        self.assertLess(result.stdout.index("reboot scheduled on zrrh"), result.stdout.index("reboot scheduled on adeck"))
        self.assertIn("--on-active=5", (self.root / "ssh.log").read_text())
        self.assertIn("--on-active=20", (self.root / "reboot.log").read_text())

    def test_multi_host_switch_activates_in_order_without_reboot(self):
        result = self.invoke("deploy", "zrrh", "adeck", "--switch", host="zrrh")
        self.assertIn("Deploy order: adeck zrrh (switch)", result.stdout)
        self.assertEqual(self.trace(), ["sync", "nh", "nh"])
        self.assertLess(result.stdout.index("==> deploy adeck"), result.stdout.index("==> deploy zrrh"))
        self.assertIn("os\nswitch\n-H\nadeck", (self.root / "nh.log").read_text())
        self.assertIn("--target-host", (self.root / "nh.log").read_text())
        self.assertFalse((self.root / "reboot.log").exists())

    def test_general_help_distinguishes_image_from_build(self):
        result = self.invoke("-h")
        self.assertIn("zcli build <host> builds that host's system closure", result.stdout)
        self.assertIn("zcli image tm20 builds the flashable SD card .img", result.stdout)
        self.assertEqual(self.trace(), [])

    def test_image_help_prints_flash_commands_without_building(self):
        result = self.invoke("image", "-h")
        self.assertIn("sudo dd if=/mnt/echo/nix-os/result-sd-tm20 of=/dev/sdb", result.stdout)
        self.assertIn("sudo rsync -a /mnt/echo/nix-os/secrets/", result.stdout)
        self.assertEqual(self.trace(), [])

    def test_image_dry_does_not_copy(self):
        self.invoke("image", "tm20", "--dry")
        ssh = (self.root / "ssh.log").read_text()
        self.assertIn("--dry-run", ssh)
        self.assertIn("--what=sleep", ssh)
        self.assertIn("--why=zcli image tm20", ssh)
        self.assertNotIn("--out-link", ssh)
        self.assertFalse((self.root / "nix.log").exists())

    def test_image_builds_on_zrrh_and_copies_back(self):
        result = self.invoke("image", "tm20")
        self.assertIn("result-sd-tm20", (self.root / "ssh.log").read_text())
        nix = (self.root / "nix.log").read_text()
        self.assertIn("copy", nix)
        self.assertIn("/nix/store/fake-sd-image", nix)
        self.assertIn(str(self.root / "result-sd-tm20"), result.stdout)
        self.assertTrue((self.root / "result-sd-tm20").is_symlink())
