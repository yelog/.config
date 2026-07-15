# DAP Visual Style Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make nvim-dap breakpoints and stopped execution lines clearly visible in the existing TokyoNight theme without adding a UI dependency.

**Architecture:** A small shared `custom.dap_style` module owns DAP semantic highlights and sign definitions. TokyoNight passes its palette to the module during `on_highlights`; nvim-dap invokes the same module after loading so signs consistently reference those groups.

**Tech Stack:** Neovim Lua, `mfussenegger/nvim-dap`, TokyoNight, headless Neovim Lua specs.

---

### Task 1: Specify the DAP visual contract

**Files:**
- Create: `nvim/tests/dap_style_spec.lua`

**Step 1: Write the failing spec**

Create a standalone headless spec that requires `custom.dap_style`, passes a representative TokyoNight palette into `apply_highlights`, and asserts:

- breakpoint, condition, rejected, logpoint, and stopped groups receive the intended foreground colors;
- the stopped-line group receives a non-empty background;
- signs use `●`, `◆`, `×`, `◌`, and `▶`;
- every sign uses its semantic text and number highlight;
- `DapStopped` uses `DapStoppedLine` as `linehl`.

**Step 2: Run the spec to verify failure**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/dap_style_spec.lua" "+qa!"
```

Expected: failure because `custom.dap_style` does not exist.

### Task 2: Implement shared DAP style definitions

**Files:**
- Create: `nvim/lua/custom/dap_style.lua`
- Test: `nvim/tests/dap_style_spec.lua`

**Step 1: Add semantic highlights**

Implement `apply_highlights(hl, colors)`. Use the TokyoNight palette directly:

```lua
hl.DapBreakpoint = { fg = colors.red, bold = true }
hl.DapBreakpointCondition = { fg = colors.orange, bold = true }
hl.DapBreakpointRejected = { fg = colors.red1, bold = true }
hl.DapLogPoint = { fg = colors.blue, bold = true }
hl.DapStopped = { fg = colors.yellow, bold = true }
hl.DapStoppedLine = {
  bg = require("tokyonight.util").blend(colors.yellow, 0.18, colors.bg),
}
```

**Step 2: Add sign definitions**

Implement `apply_signs()` with `vim.fn.sign_define`:

```lua
{ name = "DapBreakpoint", text = "●", hl = "DapBreakpoint" }
{ name = "DapBreakpointCondition", text = "◆", hl = "DapBreakpointCondition" }
{ name = "DapBreakpointRejected", text = "×", hl = "DapBreakpointRejected" }
{ name = "DapLogPoint", text = "◌", hl = "DapLogPoint" }
{ name = "DapStopped", text = "▶", hl = "DapStopped", linehl = "DapStoppedLine" }
```

For each sign, set both `texthl` and `numhl` to `hl`; use no breakpoint line highlight.

**Step 3: Run the new spec**

Run the Task 1 command.

Expected: `dap-style-tests: ok`.

### Task 3: Connect TokyoNight and nvim-dap

**Files:**
- Modify: `nvim/lua/plugins/style/tokyonight.lua:40-54`
- Modify: `nvim/lua/plugins/lsp/dap.lua:4-17`
- Test: `nvim/tests/dap_style_spec.lua`

**Step 1: Wire theme highlights**

Inside TokyoNight's existing `on_highlights`, call:

```lua
require("custom.dap_style").apply_highlights(hl, c)
```

Retain the existing `Visual` override.

**Step 2: Wire sign definitions**

Inside nvim-dap's existing `config` function, call:

```lua
require("custom.dap_style").apply_signs()
```

before keymap setup. Do not change existing mappings, adapters, or plugin dependencies.

**Step 3: Verify loaded configuration**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+lua local sign = vim.fn.sign_getdefined('DapStopped')[1]; assert(sign.text == '▶ ' and sign.linehl == 'DapStoppedLine')" +qa!
```

Expected: command exits successfully.

### Task 4: Run focused and regression verification

**Files:**
- Verify: `nvim/tests/dap_style_spec.lua`
- Verify: `nvim/tests/java_debug_spec.lua`
- Verify: `nvim/lua/plugins/lsp/dap.lua`
- Verify: `nvim/lua/plugins/style/tokyonight.lua`

**Step 1: Run focused tests**

Run independently:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/dap_style_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/java_debug_spec.lua" "+qa!"
```

Expected: both specs print their `*-tests: ok` markers.

**Step 2: Check startup and diff hygiene**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua +qa!
git diff --check
```

Expected: both commands exit successfully.

Do not commit unless explicitly requested by the user.
