# Kitty IGit Working Directory Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Cmd+G open IGit in the focused terminal's actual directory, including inside Herdr.

**Architecture:** Kitty can resolve ordinary foreground processes itself, but sees only Herdr's outer process directory for nested terminals. Query Herdr's documented `pane current` CLI with the foreground process's session environment and without an inherited caller pane ID. Pass the resolved absolute directory to both Kitty and IGit. Stop with a visible error when resolution fails.

**Tech Stack:** Kitty Python kitten, Python standard library, Herdr 0.9.5 CLI, IGit CLI.

---

## Evidence

- `/Users/yelog/.config` is a Git worktree; `/Users/yelog` is not.
- Kitty window 1 runs Herdr with cwd `/Users/yelog`.
- Herdr's `.config` pane runs its shell and OpenCode in `/Users/yelog/.config`.
- `Window.cwd_of_child` reads a foreground process's OS cwd; it does not inspect Herdr panes.
- `igit --list-roots /Users/yelog/.config` correctly finds `.config`.
- Herdr's documented `foreground_cwd` is authoritative for the foreground application; `cwd` is its shell/workspace fallback.
- An inherited `HERDR_PANE_ID` makes `pane current` return the calling pane even when another pane is focused. Remove that one variable for a terminal-level shortcut.

## Task 1: Reproduce directory selection failures

**Files:** Create `kitty/tests/test_toggle_igit.py`.

1. Cover an outer Herdr cwd at home with the focused inner pane in `.config`.
2. Cover foreground cwd precedence, named sessions, a stale caller pane ID, paths with spaces, and ordinary Kitty windows.
3. Cover unavailable/invalid directory metadata and failed/timed-out CLI calls. Verify no IGit launch occurs on errors.
4. Verify the existing toggle closes IGit without querying Herdr.

Run: `python3 -m unittest discover -s kitty/tests -v`.

Expected before implementation: Herdr regression tests fail because the original kitten passes the outer process directory and omits IGit's directory argument.

## Task 2: Resolve and pass an explicit directory

**Files:** Modify `kitty/toggle_igit.py`.

1. Add a directory resolver. For Herdr, invoke its CLI with an argument list, capture JSON, and apply a 0.5-second timeout. Preserve the foreground process's session/config environment and explicit `--session` argument; remove `HERDR_PANE_ID`.
2. Prefer `result.pane.foreground_cwd`, then `result.pane.cwd`. For ordinary windows, retain Kitty's foreground cwd lookup.
3. Require an absolute existing directory. Report errors through `boss.show_error`; never fall back to another tab or the home directory after a Herdr error.
4. Launch an overlay tied to the source window with `--cwd <directory>` and `ig -- <directory>`. Keep the existing close behavior.
5. Keep remote Herdr invocations from silently querying the default local session.

## Task 3: Verify the actual integration

1. Run the targeted unit tests and Python syntax checks.
2. Use a temporary no-UI diagnostic kitten to compare the outer cwd, focused Herdr pane cwd, and final launch arguments in the running Kitty instance.
3. Verify IGit discovery with an explicit `.config` path and with temporary repositories in paths containing spaces.
4. If needed, exercise the overlay toggle in a disposable Kitty tab and close only the tab/windows created for verification.
5. Review the final diff and record the results. Do not commit, publish, upgrade, or modify IGit/Herdr application code.

Execution is already authorized by the user's request to implement the fix. Proceed in this session without a separate approval or delegation step.

## Verification results

- `python3 -m unittest discover -s kitty/tests -v`: all 11 tests passed after the final implementation.
- Kitty's bundled Python 3.14 parsed the updated kitten successfully.
- A no-UI diagnostic in the actual Herdr-backed Kitty window observed outer cwd `/Users/yelog` and final launch cwd/argument `/Users/yelog/.config`; directory resolution took 9.53 ms.
- A real overlay in a disposable Kitty tab started as `ig -- /Users/yelog/.config` with OS cwd `/Users/yelog/.config` and displayed the `.config` changes. Toggling closed the overlay and retained the underlying shell. The disposable tab was then removed.
- The installed IGit binary, invoked from `/Users/yelog` with an explicit path, correctly discovered `.config` and a temporary repository whose path contained spaces and Chinese characters.
- `git diff --check` passed. Unrelated OpenCode changes that appeared during verification were left untouched.
- Kitty compiles custom kitten files on invocation, so the existing Cmd+G mapping picks up this change without restarting or reloading Kitty.
