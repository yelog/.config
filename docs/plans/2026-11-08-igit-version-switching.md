# IGit Version Switching Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Switch Kitty and Neovim IGit launches between the installed stable binary and the local debug build with `ig-use stable`, `ig-use debug`, and `ig-use status`.

**Architecture:** One Python CLI owns an atomic selection symlink under `${XDG_STATE_HOME:-$HOME/.local/state}/igit/launcher/current`. Its `path` command resolves the complete executable path for both clients. Kitty resolves before launch; igit.nvim resolves a command callback before calculating its existing session key, retaining separate stable/debug jobs.

**Tech Stack:** Python standard library, Kitty Python kitten, Neovim Lua, local igit.nvim plugin.

---

## Existing state and boundaries

- Both shortcut configurations currently use `~/.local/bin/ig`.
- Stable installation entry: `~/.local/bin/ig`, retaining the installer's upgrade links.
- Debug build: `~/workspace/tui/igit/target/debug/ig`.
- No selection pointer or `~/.local/bin/ig-use` exists yet. Initial selection remains stable.
- The local igit.nvim repository has no commits and its existing files are untracked. Preserve that work and modify only the command resolver, its tests, and documentation.
- Do not rebuild IGit automatically, stop existing user jobs, rewrite installation links, or commit changes as part of this implementation.

## Task 1: Shared version selector

**Files:** Add `igit/launcher.py`, `igit/tests/test_launcher.py`, and `igit/README.md`; whitelist only those source files in `.gitignore`; install `~/.local/bin/ig-use` as a symlink to the executable Python source.

1. Test stable default, stable/debug selection, canonical paths, installer upgrades, XDG state paths, missing/non-executable binaries, broken selection links, unknown selections, and paths containing spaces/Unicode. Failed selection must leave the old choice unchanged.
2. Implement `stable`, `debug`, `status`, and the machine-readable `path` operation. Validate executable targets; atomically replace the selection symlink; print actionable failures without silently falling back.
3. `status` prints selected mode, installation/build entry, real executable path, and `--version` output with a bounded timeout. `path` does not execute IGit.

Run: `python3 -m unittest discover -s igit/tests -v`.

## Task 2: Kitty integration

**Files:** Modify `kitty/toggle_igit.py` and `kitty/tests/test_toggle_igit.py`.

1. Reproduce the fixed-global-executable behavior with a selected-binary regression.
2. Resolve `ig-use path` before launching, retaining the existing Herdr cwd fix, explicit workspace argument, source-window binding, and toggle close behavior.
3. Bound the selector call and show useful error text when it fails. No launch should happen with an unavailable selection.

Run: `python3 -m unittest discover -s kitty/tests -v`.

## Task 3: Neovim dynamic commands and session identity

**Files:** Modify `/Users/yelog/workspace/vi/igit.nvim/lua/igit/init.lua`, `tests/run.lua`, `README.md`, and `doc/igit.txt`; modify `nvim/lua/plugins/panel/igit.lua`.

1. Test that a function command is not evaluated during setup, resolves on every open, accepts string/argv results, preserves caller argv tables, reports failures without altering the editor, and reuses the correct stable/debug jobs.
2. Add backward-compatible callback support. Resolve before the existing `{cwd, argv}` session key; report resolution errors through the plugin's normal error path.
3. Configure the callback to invoke `ig-use path` with a one-second deadline. Every opening entrypoint uses the same callback.
4. Document callback timing, session preservation, and the need to quit an existing debug process before testing a rebuilt binary at the same path.

Run from the plugin repository: `nvim --headless -u NONE -l tests/run.lua`.

## Task 4: Install and verify

1. Make the selector executable, create the missing CLI symlink without overwriting anything, and initialize stable selection.
2. Exercise `ig-use` against the real stable/debug builds, restore stable, and confirm the installer's global links are unchanged.
3. Use disposable Kitty/Neovim sessions to verify that both clients use real selected paths and that stable/debug Neovim sessions remain independent. Tests use temporary repositories or fake processes.
4. Run targeted checks and diff checks; clean up only resources created for verification.
5. Document that existing Neovim processes need one initial configuration reload/restart; subsequent version switches require none. Existing IGit processes retain their original binary.

The user explicitly authorized implementation. Execute directly in this session without delegation or another approval step.

## Verification results

- Selector: 14 Python tests passed, including missing/unreadable selections, XDG state, atomic switches, installer upgrades, and executable paths with spaces/Unicode.
- Kitty: 16 Python tests passed, preserving Herdr directory handling and checking selector error behavior.
- igit.nvim: all 36 headless Neovim tests passed. The existing simulated Neovim 0.10 `TermRequest` test now invokes only the plugin's augroup so Neovim 0.12 built-in handlers do not receive the older event shape.
- An isolated headless Neovim instance loaded the actual personal plugin options and launched both real binaries in a temporary Git repository. Stable and debug had distinct terminal jobs; switching back resumed the original stable job while debug remained alive.
- A disposable Kitty tab launched both real stable/debug overlays in a temporary repository and rendered its file. Each overlay received the correct real executable, cwd, and explicit workspace argument. Both toggles closed only their overlays.
- Selection resolution in Kitty's bundled Python took approximately 32 ms in one observed call.
- `~/.local/bin/ig-use` is installed. Production selection was restored to stable after verification; installer-managed `ig`, `igit`, and `current` links were unchanged. Temporary test windows and repositories were removed.
- Local IGit settings/backups remain ignored. No commits were created, and existing user IGit jobs were not stopped.
