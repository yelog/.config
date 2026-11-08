import os

from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    foreground_cmd = window.child.foreground_cmdline or []
    if foreground_cmd and os.path.basename(foreground_cmd[0]) in {"ig", "igit"}:
        window.close()
        return

    cwd = window.cwd_of_child or boss.active_tab.cwd
    boss.launch("--type=overlay", "--cwd", cwd, os.path.expanduser("~/.local/bin/ig"))
