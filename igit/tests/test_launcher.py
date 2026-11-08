import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


LAUNCHER = Path(__file__).resolve().parents[1] / "launcher.py"


class LauncherTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="igit selector 中文 ")
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name).resolve()
        self.environment = dict(os.environ, HOME=str(self.home))
        self.environment.pop("XDG_STATE_HOME", None)
        self.stable = self.home / ".local/share/igit/releases/0.1.0/ig"
        self.debug = self.home / "workspace/tui/igit/target/debug/ig"
        self.global_entry = self.home / ".local/bin/ig"
        self.selection = self.home / ".local/state/igit/launcher/current"
        self.make_executable(self.stable, "stable fixture")
        self.make_executable(self.debug, "debug fixture")
        self.global_entry.parent.mkdir(parents=True)
        self.global_entry.symlink_to(self.stable)

    def make_executable(self, path, version):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"#!/bin/sh\nprintf '%s\\n' '{version}'\n")
        path.chmod(0o700)

    def run_cli(self, *arguments):
        return subprocess.run(
            [sys.executable, str(LAUNCHER), *arguments],
            env=self.environment,
            text=True,
            capture_output=True,
            timeout=5,
        )

    def assert_path(self, expected):
        result = self.run_cli("path")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, str(expected) + "\n")
        self.assertEqual(result.stderr, "")

    def test_default_uses_stable_without_creating_state(self):
        self.assert_path(self.stable)
        self.assertFalse(self.selection.parent.exists())

    def test_switches_both_ways_without_rewriting_the_installed_entry(self):
        installed_link = os.readlink(self.global_entry)
        for mode, expected in (("debug", self.debug), ("stable", self.stable)):
            with self.subTest(mode=mode):
                result = self.run_cli(mode)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(mode, result.stdout)
                self.assertTrue(self.selection.is_symlink())
                self.assert_path(expected)
                self.assertEqual(os.readlink(self.global_entry), installed_link)
                self.assertEqual(list(self.selection.parent.iterdir()), [self.selection])

    def test_status_identifies_the_binary_even_when_version_numbers_match(self):
        result = self.run_cli("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        for value in ("stable", str(self.global_entry), str(self.stable), "stable fixture"):
            self.assertIn(value, result.stdout)
        self.assertEqual(self.run_cli().stdout, result.stdout)

    def test_stable_selection_follows_installer_upgrades(self):
        self.assertEqual(self.run_cli("stable").returncode, 0)
        upgraded = self.home / ".local/share/igit/releases/0.2.0/ig"
        self.make_executable(upgraded, "new stable fixture")
        self.global_entry.unlink()
        self.global_entry.symlink_to(upgraded)
        self.assert_path(upgraded)

    def test_missing_debug_does_not_replace_stable_selection(self):
        self.assertEqual(self.run_cli("stable").returncode, 0)
        previous = os.readlink(self.selection)
        self.debug.unlink()
        result = self.run_cli("debug")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cargo build", result.stderr)
        self.assertEqual(os.readlink(self.selection), previous)
        self.assert_path(self.stable)

    def test_non_executable_debug_does_not_replace_stable_selection(self):
        self.assertEqual(self.run_cli("stable").returncode, 0)
        self.debug.chmod(0o600)
        result = self.run_cli("debug")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(str(self.debug), result.stderr)
        self.assert_path(self.stable)

    def test_deleted_selected_build_never_falls_back_to_stable(self):
        self.assertEqual(self.run_cli("debug").returncode, 0)
        self.debug.unlink()
        result = self.run_cli("path")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("debug", result.stderr)
        self.assertIn("ig-use stable", result.stderr)

    def test_xdg_state_directory_is_shared_by_all_commands(self):
        state = self.home / "custom state 中文"
        self.environment["XDG_STATE_HOME"] = str(state)
        result = self.run_cli("debug")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((state / "igit/launcher/current").is_symlink())
        self.assertFalse(self.selection.parent.exists())
        self.assert_path(self.debug)

    def test_unknown_command_does_not_change_selection(self):
        self.assertEqual(self.run_cli("debug").returncode, 0)
        result = self.run_cli("preview")
        self.assertNotEqual(result.returncode, 0)
        self.assert_path(self.debug)

    def test_regular_file_at_selection_path_is_preserved(self):
        self.selection.parent.mkdir(parents=True)
        self.selection.write_text("existing user data")
        result = self.run_cli("stable")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.selection.read_text(), "existing user data")

    def test_unknown_selection_target_is_reported(self):
        self.selection.parent.mkdir(parents=True)
        self.selection.symlink_to(self.home / "unknown/ig")
        result = self.run_cli("path")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_path_does_not_execute_the_selected_binary(self):
        self.stable.write_text("#!/bin/sh\nexit 99\n")
        self.assert_path(self.stable)

    def test_relative_state_directory_is_rejected(self):
        self.environment["XDG_STATE_HOME"] = "relative-state"
        result = self.run_cli("debug")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("absolute", result.stderr)

    @unittest.skipIf(os.geteuid() == 0, "Root bypasses directory permission checks")
    def test_unreadable_selection_never_falls_back_to_stable(self):
        self.assertEqual(self.run_cli("debug").returncode, 0)
        self.selection.parent.chmod(0)
        try:
            result = self.run_cli("path")
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(result.stdout, "")
        finally:
            self.selection.parent.chmod(0o700)


if __name__ == "__main__":
    unittest.main()
