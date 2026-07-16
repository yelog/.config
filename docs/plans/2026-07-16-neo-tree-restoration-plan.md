# Neo-tree Restoration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore the historical Neo-tree sidebar and make `<leader>te` toggle it from the left.

**Architecture:** Reintroduce the last active Neo-tree plugin specification from `7957d97^`, retaining its UI, filtering, Git, diagnostics, buffer, and custom-command settings. Correct only the historical NUI dependency spelling. Keep Yazi on `<C-e>` and remap `<leader>te` to the historical Neo-tree command.

**Tech Stack:** Neovim 0.11, Lua, lazy.nvim, neo-tree.nvim, native headless Neovim tests.

---

### Task 1: Add a Neo-tree Configuration Regression Test

**Files:**
- Create: `nvim/tests/neo_tree_spec.lua`
- Reference: `nvim/lua/plugins/panel/neo-tree.lua` from `7957d97^`
- Reference: `nvim/tests/theme_persistence_spec.lua:1-15`

**Step 1: Write the failing test**

Create a headless spec that stubs `neo-tree.setup`, loads `nvim/lua/plugins/panel/neo-tree.lua` with `dofile`, invokes its `config`, and asserts the restored contract.

```lua
local captured
package.preload["neo-tree"] = function()
  return { setup = function(opts) captured = opts end }
end

local spec = dofile(config_root .. "/lua/plugins/panel/neo-tree.lua")
assert_equal("nvim-neo-tree/neo-tree.nvim", spec[1], "Neo-tree plugin should be restored")
assert_equal("MunifTanjim/nui.nvim", spec.dependencies[3], "NUI dependency should use its valid name")
spec.config()

assert_equal("left", captured.window.position, "sidebar should be on the left")
assert_equal(40, captured.window.width, "sidebar should retain its historical width")
assert_equal(true, captured.filesystem.follow_current_file, "filesystem should follow the current file")
assert_equal(true, captured.filesystem.filtered_items.hide_dotfiles, "dotfiles should remain hidden")
assert(captured.filesystem.commands.avante_add_files, "Avante command should be restored")
```

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/neo_tree_spec.lua" "+qa!"
```

Expected: failure because the Neo-tree plugin specification file is absent.

### Task 2: Restore the Historical Neo-tree Specification

**Files:**
- Create: `nvim/lua/plugins/panel/neo-tree.lua`
- Test: `nvim/tests/neo_tree_spec.lua`

**Step 1: Restore the active historical configuration**

Recreate `7957d97^:nvim/lua/plugins/panel/neo-tree.lua` as an active Lazy specification. Preserve its 40-column left sidebar, custom indentation and icon configuration, Git symbols, mappings, file filters, current-file following, buffer source, Git-status float, and the image-preview/Avante commands.

Use this dependency list, correcting the one historical spelling error:

```lua
dependencies = {
  "nvim-lua/plenary.nvim",
  "nvim-tree/nvim-web-devicons",
  "MunifTanjim/nui.nvim",
}
```

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/neo_tree_spec.lua" "+qa!"
```

Expected: `neo-tree-tests: ok`.

### Task 3: Restore the Neo-tree Toggle Mapping

**Files:**
- Modify: `nvim/lua/key-map.lua:433-448`

**Step 1: Change only `<leader>te`**

Keep the `<C-e>` Yazi toggle. Replace the `<leader>te` Yazi mapping with the historical command mapping:

```lua
map("n", "<leader>te", "<cmd>Neotree left toggle<cr>", { desc = "Toggle Neo-tree" })
```

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/neo_tree_spec.lua" "+qa!"
```

Expected: `neo-tree-tests: ok`.

### Task 4: Validate the Full Configuration and Mapping

**Files:**
- Verify: `nvim/lua/plugins/panel/neo-tree.lua`
- Verify: `nvim/lua/key-map.lua`
- Verify: `nvim/tests/neo_tree_spec.lua`

**Step 1: Verify command and mapping availability**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+lua assert(vim.fn.exists(':Neotree') == 2); assert(vim.fn.maparg(' te', 'n'):find('Neotree left toggle', 1, true))" "+qa!"
```

Expected: exit code 0.

**Step 2: Review scoped changes**

Run:

```bash
git diff --check -- docs/plans/2026-07-16-neo-tree-restoration-design.md docs/plans/2026-07-16-neo-tree-restoration-plan.md nvim/lua/plugins/panel/neo-tree.lua nvim/lua/key-map.lua nvim/tests/neo_tree_spec.lua
```

Expected: no whitespace errors. Do not commit unless explicitly requested.
