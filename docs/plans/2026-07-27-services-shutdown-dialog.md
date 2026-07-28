# Services Shutdown Dialog Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display active services and Java-debug shutdown progress in a centered floating window during Neovim exit.

**Architecture:** A dedicated dialog module turns lifecycle status updates into a non-focusable floating buffer. `services.lifecycle` remains the only shutdown coordinator; the service bootstrap supplies the dialog renderer to its existing callback option.

**Tech Stack:** Neovim Lua, Neovim floating-window API, existing services lifecycle runtime.

---

### Task 1: Test dialog state handling

**Files:**
- Create: `nvim/tests/services_shutdown_dialog_spec.lua`
- Create: `nvim/lua/services/shutdown_dialog.lua`

**Step 1: Write failing tests**

Stub Neovim buffer/window APIs and assert that `render(message, status)` does not create a buffer for a nil status, creates one for a closing status, updates its lines for force status, and closes it when lifecycle passes `nil, nil`.

**Step 2: Run the test to verify it fails**

Run: `nvim --headless -l nvim/tests/services_shutdown_dialog_spec.lua`

Expected: FAIL because `services.shutdown_dialog` does not exist.

**Step 3: Implement the dialog module**

Implement `M.render(_, status)` with module-local buffer and window IDs. Create a scratch, unlisted buffer and an `nvim_open_win` configuration using `relative = "editor"`, `row = math.floor((vim.o.lines - height) / 2)`, `col = math.floor((vim.o.columns - width) / 2)`, `focusable = false`, and `zindex = 100`. Render the status text and a concise wait message. Reconfigure position on updates. On nil status, close the window and delete the buffer.

**Step 4: Run the focused test**

Run: `nvim --headless -l nvim/tests/services_shutdown_dialog_spec.lua`

Expected: `services-shutdown-dialog-spec-tests: ok`.

**Step 5: Force redraw after dialog updates**

After opening or reconfiguring the floating window, call `vim.cmd("redraw!")`. The shutdown lifecycle uses `vim.wait`, so buffered redraws can otherwise leave the window frame visible while its text is blank.

### Task 2: Wire the dialog into the existing exit lifecycle

**Files:**
- Modify: `nvim/lua/plugins/panel/overseer.lua:3-6`
- Modify: `nvim/tests/services_lifecycle_spec.lua`

**Step 1: Add a failing bootstrap assertion**

Assert the service bootstrap passes `render_shutdown_status = require("services.shutdown_dialog").render` to `services.lifecycle.setup`.

**Step 2: Run the test to verify it fails**

Run: `nvim --headless -l nvim/tests/services_lifecycle_spec.lua`

Expected: FAIL because the dialog is not wired into lifecycle setup.

**Step 3: Pass the renderer to lifecycle setup**

Replace the unconfigured setup call with:

```lua
require("services.lifecycle").setup(runtime, {
  render_shutdown_status = require("services.shutdown_dialog").render,
})
```

Do not modify the `Q` mapping or lifecycle shutdown orchestration.

**Step 4: Run focused tests**

Run: `nvim --headless -l nvim/tests/services_shutdown_dialog_spec.lua && nvim --headless -l nvim/tests/services_lifecycle_spec.lua`

Expected: both scripts pass.

### Task 3: Validate configuration and behavior

**Files:**
- Verify: `nvim/lua/services/shutdown_dialog.lua`
- Verify: `nvim/lua/plugins/panel/overseer.lua`

**Step 1: Run all related checks**

Run: `nvim --headless -l nvim/tests/services_shutdown_dialog_spec.lua && nvim --headless -l nvim/tests/services_lifecycle_spec.lua && nvim --headless "+qa" && git diff --check`

Expected: tests pass, headless startup succeeds, and no whitespace errors are reported.

**Step 2: Manually verify exit behavior**

Start a service, press `Q`, and verify a centered, non-focusable dialog shows graceful-shutdown progress then forced-shutdown messaging when necessary. Press `Q` with no active services and verify Neovim exits without a dialog. Attempt `Q` with an unsaved modified buffer and verify the quit fails without triggering service shutdown.
