# Embedded IGit Pane Maximize Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Cmd+Ctrl+F toggle the focused embedded IGit pane without maximizing its Neovim float or changing the surrounding Kitty layout.

**Architecture:** Before changing an outer layout, Kitty's existing zoom script asks only the source window's Neovim instance whether the focused buffer is an IGit terminal. A shared Neovim helper sends the configured CSI-u chord directly to that terminal job and reports that the request was handled. Existing SmartZoom and buffer mappings use the same helper; ordinary editor zoom retains its existing behavior.

**Tech Stack:** Bash, Python unittest, Neovim Lua and RPC, Kitty remote control.

---

### Task 1: Reproduce both routing boundaries

**Files:**
- Create: `nvim/tests/igit_terminal_spec.lua`
- Create: `kitty/tests/test_sync_zoom.py`

Run a real terminal job in a Neovim float and verify exact shortcut bytes, unchanged float geometry, repeated toggles, dead jobs, and unrelated focused buffers. Start isolated Neovim RPC servers with a fake Kitty command to prove that an embedded request returns before any outer layout or SmartZoom action, only the source window receives it, and ordinary editing retains existing synchronization.

Run:

```sh
nvim --headless -u NONE -l nvim/tests/igit_terminal_spec.lua
python3 -m unittest discover -s kitty/tests -p test_sync_zoom.py -v
```

Expected before implementation: failure for the missing helper and the incorrect outer zoom.

### Task 2: Give the embedded terminal first refusal

**Files:**
- Create: `nvim/lua/custom/igit_terminal.lua`
- Modify: `nvim/lua/key-map.lua`
- Modify: `nvim/after/ftplugin/igit.lua`
- Modify: `kitty/sync_zoom.sh`

Expose `require("custom.igit_terminal").toggle_maximize()`. Return false for non-IGit buffers; for an IGit terminal, send `"\27[102;13u"` to its running job and return true. Keep failed or exited IGit requests inside that context and report the failure.

Invoke the helper before SmartZoom's window-count/Zen logic and from the IGit buffer-local shortcut. Extend the zoom script's source metadata with its focused process, match the source Neovim socket through process ancestry, and call the helper over RPC before changing any outer layout.

### Task 3: Verify and activate

Run the focused tests, `bash -n kitty/sync_zoom.sh`, and `git diff --check`. Exercise the real debug IGit binary in a temporary Git repository through an isolated Kitty and Neovim session, including maximize, restore, Tab focus, ordinary editor fallback, and unchanged Git state.

The shell script is read on each shortcut, and existing Neovim sessions can load the new helper through the RPC request. Update the local integration notes with the routing rule and verification commands. Preserve unrelated configuration changes; do not commit or alter application repositories.

### Observed verification

- Before the fix, three script tests reproduced outer zoom, changes to multiple Neovim instances, and failure to resolve an inactive source tab.
- The terminal routing test used a real PTY job to verify exact input bytes, repeat invocations, float geometry, direct terminal mappings, unrelated buffers, and exited jobs.
- An isolated hidden Kitty instance opened the real selected debug IGit through the configured Cmd+G callback. Single-window and split-window maximize/restore, Tab traversal, direct terminal input, and ordinary Kitty/Neovim zoom restoration passed. The fixture's HEAD, index, and working changes were preserved.
