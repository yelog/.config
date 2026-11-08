import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import ModuleType, SimpleNamespace
import unittest
from unittest.mock import Mock, patch


# The kitten runs inside Kitty; keep regression tests runnable with system Python.
handler = ModuleType("kittens.tui.handler")
handler.result_handler = lambda **kwargs: lambda function: function
with patch.dict(sys.modules, {"kittens.tui.handler": handler}):
    spec = importlib.util.spec_from_file_location(
        "toggle_igit", Path(__file__).resolve().parents[1] / "toggle_igit.py"
    )
    toggle_igit = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(toggle_igit)


class ToggleIGitTests(unittest.TestCase):
    def setUp(self):
        self.binary = "/selected/build/ig"
        executable = patch.object(toggle_igit, "igit_executable", return_value=self.binary, create=True)
        self.executable = executable.start()
        self.addCleanup(executable.stop)
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        self.project = self.home / ".config"
        self.project.mkdir()
        self.other_project = self.home / "another project 中文"
        self.other_project.mkdir()
        self.window = SimpleNamespace(
            id=42,
            cwd_of_child=str(self.home),
            close=Mock(),
            child=SimpleNamespace(
                foreground_cmdline=["/Users/yelog/.local/bin/herdr"],
                foreground_environ={
                    "PATH": os.environ.get("PATH", ""),
                    "HOME": str(self.home),
                    "HERDR_SOCKET_PATH": "/session/herdr.sock",
                    "HERDR_PANE_ID": "stale:pane",
                },
            ),
        )
        self.boss = SimpleNamespace(
            window_id_map={42: self.window},
            active_tab=SimpleNamespace(cwd=str(self.home)),
            launch=Mock(),
            show_error=Mock(),
        )

    def invoke(self):
        toggle_igit.handle_result([], None, 42, self.boss)

    def response(self, **pane):
        return subprocess.CompletedProcess(
            [], 0, json.dumps({"result": {"pane": pane}}), ""
        )

    def assert_launch_directory(self, directory):
        self.boss.show_error.assert_not_called()
        self.boss.launch.assert_called_once()
        arguments = self.boss.launch.call_args.args
        self.assertEqual(arguments[arguments.index("--cwd") + 1], str(directory))
        self.assertEqual(arguments[-2:], ("--", str(directory)))
        self.assertIn("--type=overlay", arguments)
        self.assertIn("--source-window=id:42", arguments)
        self.assertIn("--next-to=id:42", arguments)

    def test_herdr_uses_focused_pane_instead_of_outer_home_directory(self):
        with patch("subprocess.run", return_value=self.response(
            cwd=str(self.project), foreground_cwd=str(self.project)
        )) as run:
            self.invoke()
        self.assert_launch_directory(self.project)
        arguments, = run.call_args.args
        self.assertEqual(arguments[-2:], ["pane", "current"])
        environment = run.call_args.kwargs["env"]
        self.assertNotIn("HERDR_PANE_ID", environment)
        self.assertEqual(environment["HERDR_SOCKET_PATH"], "/session/herdr.sock")
        self.assertEqual(self.window.child.foreground_environ["HERDR_PANE_ID"], "stale:pane")
        self.assertLessEqual(run.call_args.kwargs["timeout"], 0.5)

    def test_herdr_prefers_foreground_directory_and_preserves_spaces_and_unicode(self):
        with patch("subprocess.run", return_value=self.response(
            cwd=str(self.project), foreground_cwd=str(self.other_project)
        )):
            self.invoke()
        self.assert_launch_directory(self.other_project)

    def test_herdr_uses_pane_directory_when_foreground_directory_is_missing(self):
        with patch("subprocess.run", return_value=self.response(cwd=str(self.project))):
            self.invoke()
        self.assert_launch_directory(self.project)

    def test_herdr_preserves_explicit_named_session(self):
        for option in (["--session", "work"], ["--session=work"]):
            with self.subTest(option=option):
                self.boss.launch.reset_mock()
                self.window.child.foreground_cmdline = ["/bin/herdr", *option]
                with patch("subprocess.run", return_value=self.response(
                    cwd=str(self.project)
                )) as run:
                    self.invoke()
                self.assert_launch_directory(self.project)
                self.assertEqual(run.call_args.args[0], ["/bin/herdr", *option, "pane", "current"])

    def test_ordinary_kitty_window_uses_its_foreground_directory(self):
        self.window.child.foreground_cmdline = ["/bin/zsh"]
        self.window.cwd_of_child = str(self.project)
        with patch("subprocess.run") as run:
            self.invoke()
        run.assert_not_called()
        self.assert_launch_directory(self.project)

    def test_launch_uses_the_currently_selected_binary(self):
        self.window.child.foreground_cmdline = ["/bin/zsh"]
        self.window.cwd_of_child = str(self.project)
        self.invoke()
        self.assertEqual(self.boss.launch.call_args.args[-3], self.binary)

    def test_unavailable_selection_does_not_launch_another_version(self):
        self.window.child.foreground_cmdline = ["/bin/zsh"]
        self.window.cwd_of_child = str(self.project)
        self.executable.side_effect = ValueError("Selected debug build is unavailable")
        self.invoke()
        self.boss.launch.assert_not_called()
        self.boss.show_error.assert_called_once()

    def test_selector_error_shows_the_build_instruction(self):
        self.window.child.foreground_cmdline = ["/bin/zsh"]
        self.window.cwd_of_child = str(self.project)
        self.executable.side_effect = subprocess.CalledProcessError(
            1, ["ig-use", "path"], stderr="Selected debug build is unavailable. Run cargo build."
        )
        self.invoke()
        self.boss.launch.assert_not_called()
        self.assertIn("Run cargo build", self.boss.show_error.call_args.args[1])

    def test_unavailable_metadata_does_not_launch_in_home(self):
        failures = [
            self.response(),
            self.response(cwd="relative/path"),
            self.response(cwd=str(self.home / "deleted")),
            self.response(cwd=str(self.home), foreground_cwd=str(self.home / "deleted")),
            self.response(cwd=123),
            subprocess.CompletedProcess([], 0, "not json", ""),
            subprocess.CompletedProcess([], 0, '{"error":{"code":"unavailable"}}', ""),
            subprocess.CompletedProcess([], 0, '[]', ""),
        ]
        for response in failures:
            with self.subTest(response=response.stdout):
                self.boss.show_error.reset_mock()
                with patch("subprocess.run", return_value=response):
                    self.invoke()
                self.boss.launch.assert_not_called()
                self.boss.show_error.assert_called_once()

    def test_herdr_timeout_or_failure_does_not_launch_in_home(self):
        failures = [
            subprocess.TimeoutExpired("herdr", 0.5),
            subprocess.CalledProcessError(1, ["herdr"]),
            FileNotFoundError("herdr unavailable"),
        ]
        for error in failures:
            with self.subTest(error=error):
                self.boss.show_error.reset_mock()
                with patch("subprocess.run", side_effect=error):
                    self.invoke()
                self.boss.launch.assert_not_called()
                self.boss.show_error.assert_called_once()

    def test_remote_herdr_does_not_query_the_default_local_session(self):
        for option in (["--remote", "host"], ["--machine=host"]):
            with self.subTest(option=option):
                self.boss.show_error.reset_mock()
                self.window.child.foreground_cmdline = ["/bin/herdr", *option]
                with patch("subprocess.run") as run:
                    self.invoke()
                run.assert_not_called()
                self.boss.launch.assert_not_called()
                self.boss.show_error.assert_called_once()

    def test_missing_ordinary_directory_does_not_fall_back_to_another_tab(self):
        self.window.child.foreground_cmdline = ["/bin/zsh"]
        self.window.cwd_of_child = None
        self.invoke()
        self.boss.launch.assert_not_called()
        self.boss.show_error.assert_called_once()

    def test_toggle_closes_igit_without_directory_lookup(self):
        for executable in ("ig", "igit"):
            with self.subTest(executable=executable):
                self.window.close.reset_mock()
                self.window.child.foreground_cmdline = [f"/bin/{executable}"]
                with patch("subprocess.run") as run:
                    self.invoke()
                self.window.close.assert_called_once()
                run.assert_not_called()
                self.boss.launch.assert_not_called()

    def test_closed_target_window_is_ignored(self):
        self.boss.window_id_map.clear()
        self.invoke()
        self.boss.launch.assert_not_called()
        self.boss.show_error.assert_not_called()


class IGitExecutableTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="igit binary 中文 ")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name).resolve()
        self.binary = self.directory / "ig"
        self.binary.write_text("#!/bin/sh\nexit 0\n")
        self.binary.chmod(0o700)

    def test_selector_returns_a_canonical_executable_with_spaces(self):
        response = subprocess.CompletedProcess([], 0, str(self.binary) + "\n", "")
        with patch("subprocess.run", return_value=response) as run:
            self.assertEqual(toggle_igit.igit_executable(), str(self.binary))
        self.assertEqual(run.call_args.args[0], [os.path.expanduser("~/.local/bin/ig-use"), "path"])
        self.assertEqual(run.call_args.kwargs["timeout"], 1)
        self.assertTrue(run.call_args.kwargs["check"])

    def test_selector_rejects_unavailable_or_invalid_output(self):
        for output in ("", "relative/ig", str(self.directory), str(self.directory / "missing")):
            with self.subTest(output=output):
                response = subprocess.CompletedProcess([], 0, output + "\n", "")
                with patch("subprocess.run", return_value=response):
                    with self.assertRaises(ValueError):
                        toggle_igit.igit_executable()
        self.binary.chmod(0o600)
        response = subprocess.CompletedProcess([], 0, str(self.binary) + "\n", "")
        with patch("subprocess.run", return_value=response):
            with self.assertRaises(ValueError):
                toggle_igit.igit_executable()


if __name__ == "__main__":
    unittest.main()
