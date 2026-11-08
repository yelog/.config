#!/usr/bin/env python3
"""Select the IGit executable shared by Kitty and Neovim."""

import os
from pathlib import Path
import stat
import subprocess
import sys


USAGE = "Usage: ig-use [stable|debug|status|path]"


def binaries():
    home = Path.home()
    return {
        "stable": home / ".local/bin/ig",
        "debug": home / "workspace/tui/igit/target/debug/ig",
    }


def selection_path():
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    if not state.is_absolute():
        raise ValueError("XDG_STATE_HOME must be an absolute path.")
    return state / "igit/launcher/current"


def check_selection_file(path):
    try:
        metadata = path.lstat()
    except FileNotFoundError:
        return False
    if not stat.S_ISLNK(metadata.st_mode):
        raise ValueError(f"Selection path is not a symlink; left unchanged: {path}")
    return True


def selected():
    path = selection_path()
    if not check_selection_file(path):
        return "stable"
    target = Path(os.path.abspath(path.parent / os.readlink(path)))
    for mode, entry in binaries().items():
        if target == entry:
            return mode
    raise ValueError(f"Unknown selection target: {target}. Run ig-use stable or ig-use debug.")


def executable(mode):
    entry = binaries()[mode]
    try:
        target = entry.resolve(strict=True)
        if target.is_file() and os.access(target, os.X_OK):
            return target
    except (OSError, RuntimeError):
        pass
    hint = (
        f"Build it with: cargo build --locked --manifest-path {Path.home() / 'workspace/tui/igit/Cargo.toml'} --bin ig. "
        "Or run ig-use stable."
        if mode == "debug"
        else "Install IGit, or run ig-use debug after building the local binary."
    )
    raise ValueError(f"The {mode} executable is unavailable or not executable: {entry}\n{hint}")


def resolve():
    return executable(selected())


def select(mode):
    target = executable(mode)
    path = selection_path()
    check_selection_file(path)
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_name(f".current-{os.getpid()}-{os.urandom(4).hex()}")
    try:
        temporary.symlink_to(binaries()[mode])
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)
    return target


def status():
    mode = selected()
    target = executable(mode)
    result = subprocess.run(
        [str(target), "--version"],
        capture_output=True,
        text=True,
        check=True,
        timeout=2,
    )
    return (
        f"Selected: {mode}\n"
        f"Entry: {binaries()[mode]}\n"
        f"Executable: {target}\n"
        f"Version: {result.stdout.strip()}"
    )


def main(arguments=None):
    arguments = sys.argv[1:] if arguments is None else arguments
    if arguments in (["--help"], ["-h"]):
        print(USAGE)
        print("Select stable/debug for future Kitty and Neovim opens. Default: stable.")
        print("status shows the selection; path prints only the resolved executable.")
        return 0
    if len(arguments) > 1:
        print(USAGE, file=sys.stderr)
        return 1
    command = arguments[0] if arguments else "status"
    try:
        if command in {"stable", "debug"}:
            target = select(command)
            print(f"Selected: {command}\nExecutable: {target}")
        elif command == "path":
            print(resolve())
        elif command == "status":
            print(status())
        else:
            raise ValueError(USAGE)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"ig-use: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
