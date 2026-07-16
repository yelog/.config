# Neovim Theme Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore the most recently selected Neovim colorscheme across all startup modes.

**Architecture:** Add a small `custom.theme` module that persists `vim.g.colors_name` and `vim.o.background` as JSON in Neovim's state directory. Run it after Lazy loads installed theme plugins, making it the sole startup theme selector. Preserve Resession for layouts and buffers, but pass its declared options into setup without enabling its per-directory colorscheme extension.

**Tech Stack:** Neovim 0.11, Lua, lazy.nvim, Resession.nvim, native headless Neovim tests.

---

### Task 1: Add Theme Persistence Regression Tests

**Files:**
- Create: `nvim/tests/theme_persistence_spec.lua`
- Reference: `nvim/tests/dap_breakpoints_spec.lua:1-17`
- Reference: `nvim/lua/plugins/auto-session.lua:50-88`

**Step 1: Write the failing test**

Create a headless test that adds `nvim/lua` to `package.path`, creates a temporary JSON state path, and exercises `custom.theme` with builtin `blue` and `default` colorschemes.

```lua
local theme = require("custom.theme")
local state_path = vim.fn.tempname() .. "/theme.json"

vim.fn.mkdir(vim.fs.dirname(state_path), "p")
vim.fn.writefile({ vim.json.encode({ colorscheme = "blue", background = "dark" }) }, state_path)
theme.setup({ path = state_path, default = "default" })
assert_equal("blue", vim.g.colors_name, "saved colorscheme should restore")

vim.cmd.colorscheme("default")
local saved = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
assert_equal("default", saved.colorscheme, "ColorScheme should persist immediately")

vim.fn.writefile({ vim.json.encode({ colorscheme = "missing-theme" }) }, state_path)
theme.setup({ path = state_path, default = "blue" })
assert_equal("blue", vim.g.colors_name, "missing saved theme should fall back")
```

Also stub `resession`, load the plugin specification with `dofile`, invoke its config with the declared `opts`, and assert `resession.setup` receives that exact table.

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/theme_persistence_spec.lua" "+qa!"
```

Expected: failure because `custom.theme` does not exist and Resession ignores `opts`.

### Task 2: Implement Global Theme State

**Files:**
- Create: `nvim/lua/custom/theme.lua`
- Modify: `nvim/init.lua:45-58`
- Modify: `nvim/lua/plugins/style/tokyonight.lua:57`
- Test: `nvim/tests/theme_persistence_spec.lua`

**Step 1: Implement the state module**

Implement `custom.theme.setup(opts)` with optional test-only `path` and `default` overrides. It must:

- Read JSON state only when it contains a non-empty string colorscheme.
- Register a cleared `ColorScheme` augroup that writes `{ colorscheme, background }` immediately.
- Restore the saved background before applying its colorscheme.
- Use `pcall(vim.cmd.colorscheme, { args = { name } })` and fall back to the configured default if the saved theme is unavailable.

```lua
local function apply(name)
  return pcall(vim.cmd.colorscheme, { args = { name } })
end
```

Do not add a dependency or store state in the repository.

**Step 2: Make theme startup deterministic**

Remove the unconditional `:colorscheme tokyonight` command from the TokyoNight plugin specification. Call `require("custom.theme").setup()` immediately after `require("lazy").setup(...)` returns, when both TokyoNight and JB are available.

**Step 3: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/theme_persistence_spec.lua" "+qa!"
```

Expected: `theme-persistence-tests: ok`.

### Task 3: Fix Resession Option Forwarding

**Files:**
- Modify: `nvim/lua/plugins/auto-session.lua:52-61`
- Test: `nvim/tests/theme_persistence_spec.lua`

**Step 1: Forward the resolved Lazy options**

Pass `opts` to `resession.setup(opts)`. Keep the current autosave and per-directory layout callbacks intact. Do not enable Resession's `colorscheme` extension because global state must be the sole startup-theme authority.

```lua
config = function(_, opts)
  local resession = require("resession")
  resession.setup(opts)
```

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/theme_persistence_spec.lua" "+qa!"
```

Expected: `theme-persistence-tests: ok`.

### Task 4: Validate Isolated Full-Config Restoration

**Files:**
- Verify: `nvim/init.lua`
- Verify: `nvim/lua/custom/theme.lua`
- Verify: `nvim/lua/plugins/style/tokyonight.lua`
- Verify: `nvim/lua/plugins/auto-session.lua`

**Step 1: Verify startup and persistence in isolated state**

Use a temporary `XDG_STATE_HOME` so validation does not change the user's persisted choice. Start once, switch to JB, exit, then start again with the same state directory and assert `vim.g.colors_name == "jb"`.

**Step 2: Verify fallback and formatting**

Run the focused test, load the full configuration with no saved state, and run:

```bash
git diff --check -- docs/plans/2026-07-16-neovim-theme-persistence-design.md docs/plans/2026-07-16-neovim-theme-persistence-plan.md nvim/init.lua nvim/lua/custom/theme.lua nvim/lua/plugins/style/tokyonight.lua nvim/lua/plugins/auto-session.lua nvim/tests/theme_persistence_spec.lua
```

Expected: all commands exit zero. Do not commit unless explicitly requested.
