# Ctrl-Q Buffer Close Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `<C-q>` delete the current buffer without closing its window or disrupting Services/Maven splits.

**Architecture:** Replace the geometry-sensitive `<C-q>` handler with the existing `Snacks.bufdelete()` layout-preserving buffer deletion API. Remove the now-unused local split classifier. Add a focused configuration regression assertion to prevent the old window-closing implementation from returning.

**Tech Stack:** Neovim Lua, snacks.nvim, headless Neovim specs.

---

### Task 1: Lock the intended mapping behavior with a configuration spec

**Files:**
- Modify: `nvim/tests/config_correctness_spec.lua:19-57`

**Step 1: Write the failing test**

Add assertions after `local keymaps = read("lua/key-map.lua")` that require the `<C-q>` mapping to retain its focused Neo-tree exception, call `Snacks.bufdelete()` for files, and reject the legacy `split_type` helper:

```lua
assert_contains(keymaps,
  'map("n", "<c-q>", function()\n  if vim.bo.filetype == "neo-tree" then\n    vim.cmd("Neotree close")\n    return\n  end\n  Snacks.bufdelete()\nend, { desc = "Delete buffer" })',
  "Ctrl-Q should delete buffers without closing their windows")
assert_not_contains(keymaps, "local function split_type()",
  "Ctrl-Q should not infer window geometry before deleting a buffer")
```

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/config_correctness_spec.lua" "+qa!"
```

Expected: FAIL because `<C-q>` still uses `split_type` and native `bdelete`/`q` behavior.

### Task 2: Replace the Ctrl-Q mapping

**Files:**
- Modify: `nvim/lua/key-map.lua:31-70`

**Step 1: Write the minimal implementation**

Remove `split_type`, which is only used by the current `<C-q>` handler. Preserve the focused Neo-tree behavior and replace the handler with:

```lua
map("n", "<c-q>", function()
  if vim.bo.filetype == "neo-tree" then
    vim.cmd("Neotree close")
    return
  end
  Snacks.bufdelete()
end, { desc = "Delete buffer" })
```

`Snacks.bufdelete()` prompts for unsaved changes and swaps each window to another listed buffer before deleting the target buffer, so the Services/Maven splits remain in place.

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/config_correctness_spec.lua" "+qa!"
```

Expected: `config-correctness-tests: ok`.

**Step 3: Run the full Neovim configuration spec suite**

Run:

```bash
for test in /Users/yelog/.config/nvim/tests/*_spec.lua; do nvim --headless -u NONE "+luafile ${test}" "+qa!" || exit 1; done
```

Expected: every spec exits successfully.

**Step 4: Commit only if requested**

Do not create a commit unless the user explicitly requests one. If requested, stage only `nvim/lua/key-map.lua`, `nvim/tests/config_correctness_spec.lua`, and the related design/plan documents.
