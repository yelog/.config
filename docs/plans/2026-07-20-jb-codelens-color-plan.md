# JB CodeLens Color Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Render LSP CodeLens text in the JB colorscheme with a subdued gray foreground while retaining the theme's underline treatment.

**Architecture:** The existing JB `ColorScheme` callback is the correct post-theme hook because it already owns JB-specific highlight overrides. It will copy the resolved `LspCodeLens` attributes, change only `fg`, and write the group back after JB has applied its palette.

**Tech Stack:** Neovim 0.11 Lua, built-in LSP CodeLens, `nickkadutskyi/jb.nvim`, headless Neovim Lua specs.

---

### Task 1: Specify the JB CodeLens visual contract

**Files:**
- Create: `nvim/tests/jb_codelens_spec.lua`

**Step 1: Write the failing spec**

Force the `jb` colorscheme, then assert that `LspCodeLens` resolves to foreground `0x727782`, retains `underline = true`, and retains special underline color `0x868A91`.

**Step 2: Run the spec to verify it fails**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+luafile /Users/yelog/.config/nvim/tests/jb_codelens_spec.lua" "+qa!"
```

Expected: failure because JB currently leaves `LspCodeLens.fg` unset.

### Task 2: Apply the JB-only CodeLens override

**Files:**
- Modify: `nvim/lua/plugins/style/jb.lua:14-16`
- Test: `nvim/tests/jb_codelens_spec.lua`

**Step 1: Preserve the theme's existing CodeLens attributes**

Inside the existing `ColorScheme` callback, after the DAP override, add:

```lua
local codelens = vim.api.nvim_get_hl(0, { name = "LspCodeLens", link = false })
codelens.fg = "#727782"
vim.api.nvim_set_hl(0, "LspCodeLens", codelens)
```

**Step 2: Run the focused spec**

Run the Task 1 command.

Expected: `jb-codelens-tests: ok`.

### Task 3: Verify startup and diff hygiene

**Files:**
- Verify: `nvim/lua/plugins/style/jb.lua`
- Verify: `nvim/tests/jb_codelens_spec.lua`

**Step 1: Load the full configuration**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+qa!"
```

Expected: command exits successfully.

**Step 2: Check the diff**

Run:

```bash
git diff --check
```

Expected: no output and exit code zero.

Do not commit unless explicitly requested by the user.
