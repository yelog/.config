# Heirline Buffer Tab Spacing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Give active buffer tabs a clearly visible, theme-driven selected background.

**Architecture:** Keep the existing padded parent component and resolve its active color from `PmenuSel.bg`, a theme-defined selected-item surface. Fall back through `TabLineSel.bg`, `CursorLine.bg`, and `TabLine.bg`, while inactive buffers keep `TabLine.bg`. A focused headless test supplies deterministic highlight groups and verifies every branch of the fallback chain.

**Tech Stack:** Neovim 0.11, Lua, Heirline.nvim, native headless Neovim tests.

---

### Task 1: Cover High-Contrast Theme Selection Backgrounds

**Files:**
- Modify: `nvim/tests/heirline_tabline_spec.lua`
- Reference: `nvim/lua/plugins/panel/status-line.lua:689-695`

**Step 1: Write the failing test**

Extend the deterministic highlight table with `PmenuSel`. Keep the existing padding assertions and assert the primary `PmenuSel` color, inactive `TabLine` color, and every fallback branch.

```lua
local highlights = {
  PmenuSel = { bg = "#32426b" },
  CursorLine = { bg = "#292e42" },
  TabLineSel = { bg = "#343a55" },
  TabLine = { bg = "#000000" },
}

get_highlight = function(name) return highlights[name] or {} end

assert(captured_buffer_block[1].provider == " ", "buffer tab needs left padding")
assert(captured_buffer_block[3].provider == " ", "buffer tab needs right padding")
assert(captured_buffer_block.hl({ is_active = true }).bg == "#32426b",
  "active buffer tabs must use PmenuSel background")
assert(captured_buffer_block.hl({ is_active = false }).bg == "#000000",
  "inactive buffer padding must use the TabLine background")
highlights.PmenuSel.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#343a55",
  "active buffer tabs must fall back to TabLineSel background")
highlights.TabLineSel.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#292e42",
  "active buffer tabs must fall back to CursorLine background")
highlights.CursorLine.bg = nil
assert(captured_buffer_block.hl({ is_active = true }).bg == "#000000",
  "active buffer tabs must ultimately fall back to TabLine background")
```

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/heirline_tabline_spec.lua" "+qa!"
```

Expected: failure because the current component still uses `CursorLine` as its primary background.

### Task 2: Resolve Buffer-Tab Color From Theme Highlights

**Files:**
- Modify: `nvim/lua/plugins/panel/status-line.lua:523-526,688-698`
- Test: `nvim/tests/heirline_tabline_spec.lua`

**Step 1: Make the minimal configuration change**

Update `tabline_background` so inactive buffers use `TabLine.bg` and active buffers resolve `PmenuSel.bg`, `TabLineSel.bg`, `CursorLine.bg`, then `TabLine.bg`. Do not alter `FileIcon`, `TablineFileName`, click handlers, Git-state caching, or buffer-list behavior.

```lua
local function tabline_background(self)
  local tabline_bg = utils.get_highlight("TabLine").bg
  if not self.is_active then return tabline_bg end

  return utils.get_highlight("PmenuSel").bg
    or utils.get_highlight("TabLineSel").bg
    or utils.get_highlight("CursorLine").bg
    or tabline_bg
end

local TablineBufferBlock = {
  hl = function(self)
    return {
      bg = tabline_background(self),
    }
  end,
  { provider = " " },
  TablineFileNameBlock,
  { provider = " " },
}
```

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/heirline_tabline_spec.lua" "+qa!"
```

Expected: `heirline-tabline-tests: ok`.

### Task 3: Validate the Real Configuration

**Files:**
- Verify: `nvim/lua/plugins/panel/status-line.lua`
- Verify: `nvim/tests/heirline_tabline_spec.lua`

**Step 1: Load the full Neovim configuration headlessly**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+lua assert(vim.o.showtabline == 2)" "+qa!"
```

Expected: exit code 0, confirming that the Heirline plugin specification still initializes successfully. Also load `:colorscheme jb` headlessly and confirm its `PmenuSel` and `TabLine` groups provide backgrounds.

**Step 2: Review the scoped diff**

Run:

```bash
git diff --check -- docs/plans/2026-07-16-heirline-buffer-tab-spacing-design.md docs/plans/2026-07-16-heirline-buffer-tab-spacing-plan.md nvim/lua/plugins/panel/status-line.lua nvim/tests/heirline_tabline_spec.lua
```

Expected: no whitespace errors. Do not commit unless explicitly requested.
