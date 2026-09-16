import os
import shutil

from kittens.tui.handler import result_handler


LAZYDB_COMMAND = "lazydb"


def main(args):
    pass


def is_lazydb_window(window):
    foreground_cmd = window.child.foreground_cmdline or []
    if not foreground_cmd:
        return False

    command = os.path.basename(foreground_cmd[0])
    return command == LAZYDB_COMMAND


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    if is_lazydb_window(window):
        window.close()
        return

    cwd = window.cwd_of_child or boss.active_tab.cwd
    lazydb = shutil.which(LAZYDB_COMMAND) or LAZYDB_COMMAND

    path = os.environ.get("PATH", "")
    homebrew_paths = (
        "/opt/homebrew/bin",
        "/opt/homebrew/sbin",
    )
    merged_path = ":".join(
        dict.fromkeys((*homebrew_paths, *path.split(":")))
    )

    boss.launch(
        "--type=overlay",
        "--cwd",
        cwd,
        "--env",
        f"PATH={merged_path}",
        lazydb,
    )
