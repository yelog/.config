# Resession Autosave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Quiet Resession's periodic saves while retaining five-minute crash recovery.

**Architecture:** Keep the existing directory-scoped session load and exit-save callbacks. Change only Resession's built-in autosave configuration and extend the existing configuration spec to lock in the intended timer interval and notification behavior.

**Tech Stack:** Neovim Lua, lazy.nvim, stevearc/resession.nvim, headless Neovim specs.

---

### Task 1: Cover Quiet Periodic Autosave

**Files:**
- Modify: `nvim/tests/theme_persistence_spec.lua:40-55`
- Modify: `nvim/lua/plugins/auto-session.lua:53-57`

**Step 1: Write the failing assertions**

Extend the Resession configuration assertions:

```lua
assert_equal(300, received_opts.autosave.interval, "Resession autosave should run every five minutes")
assert_equal(false, received_opts.autosave.notify, "Resession autosave should not notify")
```

**Step 2: Run the focused spec to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile $PWD/tests/theme_persistence_spec.lua" "+qa!"
```

Expected: failure because the configuration still specifies a 60-second interval and enables notifications.

**Step 3: Apply the minimal configuration change**

Set the existing Resession autosave options to:

```lua
autosave = {
  enabled = true,
  interval = 300,
  notify = false,
},
```

Keep the existing `VimLeavePre` callback so a directory without a prior saved session is still persisted on normal exit.

**Step 4: Run the focused spec to verify it passes**

Run:

```bash
nvim --headless -u NONE "+luafile $PWD/tests/theme_persistence_spec.lua" "+qa!"
```

Expected: `theme-persistence-tests: ok`.

**Step 5: Run the full configuration spec suite**

Run:

```bash
zsh -lc 'for test in "$PWD"/tests/*_spec.lua; do nvim --headless -u NONE "+luafile $test" "+qa!" || exit 1; done'
```

Expected: every spec reports success.
