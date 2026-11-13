import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "sync_zoom.sh"
NVIM = shutil.which("nvim")


@unittest.skipUnless(NVIM, "Neovim is required")
class SyncZoomTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="igit zoom ")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.socket_directory = tempfile.TemporaryDirectory(
            prefix="nvim-igit-zoom-test-", dir="/tmp"
        )
        self.addCleanup(self.socket_directory.cleanup)
        self.calls = self.directory / "calls"
        self.kitty_state = self.directory / "kitty.json"
        binary_directory = self.directory / "bin"
        binary_directory.mkdir()
        kitty = binary_directory / "kitty"
        kitty.write_text(
            "#!/bin/sh\n"
            'if [ "$2" = ls ]; then\n'
            '  cat "$IGIT_ZOOM_TEST_STATE"\n'
            "else\n"
            '  printf "%s\\n" "$*" >> "$IGIT_ZOOM_TEST_CALLS"\n'
            "fi\n"
        )
        kitty.chmod(0o700)
        self.environment = dict(
            os.environ,
            PATH=str(binary_directory) + os.pathsep + os.environ.get("PATH", ""),
            IGIT_ZOOM_TEST_STATE=str(self.kitty_state),
            IGIT_ZOOM_TEST_CALLS=str(self.calls),
            IGIT_ZOOM_TEST_SOCKETS=self.socket_directory.name,
            KITTY_WINDOW_ID="42",
        )
        self.initialization = self.directory / "init.lua"
        self.initialization.write_text(
            """
local function record(text)
  vim.fn.writefile({ text }, vim.env.IGIT_ZOOM_TEST_CALLS, "a")
end
package.preload["custom.igit_terminal"] = function()
  return {
    toggle_maximize = function()
      if vim.bo.filetype ~= "igit" then return false end
      record("inner:" .. vim.fn.getpid())
      return true
    end,
  }
end
function SmartZoom(action)
  record("outer:" .. vim.fn.getpid() .. ":" .. tostring(action))
end
vim.fn.serverstart(vim.env.IGIT_ZOOM_TEST_SOCKETS .. "/" .. vim.fn.getpid())
"""
        )

    def server(self, embedded):
        process = subprocess.Popen(
            [NVIM, "--headless", "-u", str(self.initialization)],
            env=self.environment,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.addCleanup(self.stop_server, process)
        address = Path(self.socket_directory.name) / str(process.pid)
        self.wait_for(address.exists, "Neovim did not start its RPC socket")
        self.rpc(
            address,
            "execute('set filetype=" + ("igit" if embedded else "lua") + "')",
        )
        return process, address

    @staticmethod
    def stop_server(process):
        if process.poll() is None:
            process.terminate()
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=3)

    @staticmethod
    def wait_for(condition, message):
        deadline = time.monotonic() + 3
        while time.monotonic() < deadline:
            if condition():
                return
            time.sleep(0.02)
        raise AssertionError(message)

    def rpc(self, address, expression):
        return subprocess.run(
            [NVIM, "--server", str(address), "--remote-expr", expression],
            check=True,
            capture_output=True,
            text=True,
            timeout=3,
        )

    def state(self, focused_pid, other_pid=None, layout="splits", source=True):
        windows = [{"id": 42, "pid": focused_pid, "is_active": True}]
        if other_pid is not None:
            windows.append({"id": 43, "pid": other_pid, "is_active": False})
        self.kitty_state.write_text(
            json.dumps(
                [
                    {
                        "tabs": [
                            {
                                "id": 8,
                                "is_active": source,
                                "layout": layout,
                                "windows": windows,
                            }
                        ]
                    }
                ]
            )
        )

    def run_zoom(self):
        result = subprocess.run(
            ["/bin/bash", str(SCRIPT)],
            env=self.environment,
            text=True,
            capture_output=True,
            timeout=5,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_embedded_igit_runs_before_any_outer_zoom(self):
        process, _ = self.server(embedded=True)
        self.state(process.pid)
        self.assertEqual(self.run_zoom(), [f"inner:{process.pid}"])

    def test_only_the_source_neovim_handles_an_embedded_shortcut(self):
        process, _ = self.server(embedded=True)
        other, _ = self.server(embedded=True)
        self.state(process.pid, other.pid)
        self.assertEqual(self.run_zoom(), [f"inner:{process.pid}"])

    def test_source_window_is_resolved_even_if_its_tab_is_not_active(self):
        process, _ = self.server(embedded=True)
        self.state(process.pid, source=False)
        self.assertEqual(self.run_zoom(), [f"inner:{process.pid}"])

    def test_no_source_id_falls_back_to_the_active_window(self):
        process, _ = self.server(embedded=True)
        self.environment.pop("KITTY_WINDOW_ID")
        self.state(process.pid)
        self.assertEqual(self.run_zoom(), [f"inner:{process.pid}"])

    def test_a_missing_source_window_does_not_zoom_another_window(self):
        process, _ = self.server(embedded=True)
        self.environment["KITTY_WINDOW_ID"] = "999"
        self.state(process.pid)
        self.assertEqual(self.run_zoom(), [])

    def test_ordinary_editor_keeps_local_zoom_with_one_kitty_window(self):
        process, _ = self.server(embedded=False)
        self.state(process.pid)
        self.run_zoom()
        self.wait_for(
            lambda: self.calls.exists(), "The ordinary SmartZoom action was not run"
        )
        self.assertEqual(
            self.calls.read_text().splitlines(), [f"outer:{process.pid}:nil"]
        )

    def test_ordinary_editor_keeps_stack_synchronization(self):
        process, _ = self.server(embedded=False)
        self.state(process.pid, other_pid=1)
        self.run_zoom()
        self.wait_for(
            lambda: self.calls.exists()
            and f"outer:{process.pid}:zoom" in self.calls.read_text(),
            "The ordinary SmartZoom action was not run",
        )
        self.assertEqual(
            self.calls.read_text().splitlines(),
            ["@ action --match id:42 toggle_layout stack", f"outer:{process.pid}:zoom"],
        )

    def test_ordinary_editor_restores_stack(self):
        process, _ = self.server(embedded=False)
        self.state(process.pid, other_pid=1, layout="stack")
        self.run_zoom()
        self.wait_for(
            lambda: self.calls.exists()
            and f"outer:{process.pid}:unzoom" in self.calls.read_text(),
            "The ordinary SmartZoom restore action was not run",
        )
        self.assertEqual(
            self.calls.read_text().splitlines(),
            ["@ action --match id:42 toggle_layout stack", f"outer:{process.pid}:unzoom"],
        )


if __name__ == "__main__":
    unittest.main()
