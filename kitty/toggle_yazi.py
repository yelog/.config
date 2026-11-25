import os

from kitty.fast_data_types import add_timer
from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    foreground_cmd = window.child.foreground_cmdline
    if foreground_cmd and 'yazi' in foreground_cmd[0]:
        window.write_to_child('q')
        add_timer(lambda timer_id: window.close(), 0.1, False)
    else:
        cwd = window.cwd_of_child or boss.active_tab.cwd
        path = os.environ.get('PATH', '')
        homebrew_paths = ('/opt/homebrew/bin', '/opt/homebrew/sbin')
        merged_path = ':'.join(dict.fromkeys((*homebrew_paths, *path.split(':'))))
        boss.launch(
            '--type=overlay',
            '--cwd', cwd,
            '--env', f'PATH={merged_path}',
            '/opt/homebrew/bin/yazi',
        )
