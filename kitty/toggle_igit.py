import json
import os
import shutil
import subprocess

from kittens.tui.handler import result_handler


def main(args):
    pass


def working_directory(window):
    foreground_cmd = window.child.foreground_cmdline or []
    if foreground_cmd and os.path.basename(foreground_cmd[0]) == "herdr":
        # Kitty sees Herdr's outer cwd, not the focused pane's foreground cwd.
        env = window.child.foreground_environ.copy()
        # A terminal shortcut targets UI focus, not a stale invoking pane ID.
        env.pop("HERDR_PANE_ID", None)
        executable = foreground_cmd[0]
        if not os.path.isabs(executable):
            executable = shutil.which(executable, path=env.get("PATH", os.defpath))
            executable = executable or os.path.expanduser("~/.local/bin/herdr")

        session_args = []
        arguments = iter(foreground_cmd[1:])
        for argument in arguments:
            option = argument.split("=", 1)[0]
            if option in {"--remote", "--machine"}:
                raise ValueError("Run IGit inside the remote Herdr pane.")
            if argument == "--session":
                session = next(arguments, None)
                if not session:
                    raise ValueError("Herdr session name is unavailable.")
                session_args.extend((argument, session))
            elif option == "--session":
                session_args.append(argument)

        response = subprocess.run(
            [executable, *session_args, "pane", "current"],
            env=env,
            check=True,
            capture_output=True,
            text=True,
            timeout=0.5,
        )
        pane = json.loads(response.stdout)["result"]["pane"]
        if not isinstance(pane, dict):
            raise ValueError("Herdr returned no current pane.")
        cwd = pane.get("foreground_cwd") or pane.get("cwd")
    else:
        cwd = window.cwd_of_child

    if not isinstance(cwd, str) or not os.path.isabs(cwd) or not os.path.isdir(cwd):
        raise ValueError(f"Working directory is unavailable: {cwd!r}")
    return cwd


@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    foreground_cmd = window.child.foreground_cmdline or []
    if foreground_cmd and os.path.basename(foreground_cmd[0]) in {"ig", "igit"}:
        window.close()
        return

    try:
        cwd = working_directory(window)
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        boss.show_error(
            "IGit: working directory unavailable",
            f"Cannot determine the focused terminal's working directory.\n\n{error}",
        )
        return

    boss.launch(
        "--type=overlay",
        f"--source-window=id:{window.id}",
        f"--next-to=id:{window.id}",
        "--cwd",
        cwd,
        os.path.expanduser("~/.local/bin/ig"),
        "--",
        cwd,
    )
