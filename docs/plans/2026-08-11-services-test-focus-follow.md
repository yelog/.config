# Services Test Focus and Follow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Keep services-panel selection and FOLLOW output synchronized for Java tests started with `<leader>jt`.

**Architecture:** Centralize list-row synchronization inside `Panel:focus()` and explicitly reset test output to FOLLOW when the task runner starts or reruns a test. Existing runtime output events remain responsible for streaming and tailing log batches.

**Tech Stack:** Neovim Lua, services panel, services runtime, headless Neovim specs

---

### Task 1: Specify focus and FOLLOW behavior

**Files:**
- Modify: `nvim/tests/services_panel_spec.lua`
- Modify: `nvim/tests/task_runner_spec.lua`

**Step 1: Add failing panel assertions**

Focus a service after the panel rows are rendered. Assert the list cursor row
matches that service key and the active Neovim window remains the list window.
Append a log batch and assert the output pane remains at its final line.

**Step 2: Add failing Java task assertions**

Stub the panel focus operation and assert task startup resets the selected test
service output state to FOLLOW before the runtime starts it.

**Step 3: Run focused specs**

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/services_panel_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/task_runner_spec.lua" "+qa!"
```

Expected: FAIL until focus synchronization and test FOLLOW reset exist.

### Task 2: Implement synchronized selection and test FOLLOW

**Files:**
- Modify: `nvim/lua/services/panel.lua:309-317`
- Modify: `nvim/lua/custom/task_runner.lua:255-304`

**Step 1: Synchronize list cursor in `Panel:focus()`**

Find the requested key in `panel.rows` after displaying output and set the list
window cursor to that row without changing the active window.

**Step 2: Reset test output state to FOLLOW**

Before starting or restarting a Java test, ensure the focused service output
state has `following=true`, no unseen lines, and no stored paused view.

**Step 3: Run focused specs**

Run the two commands from Task 1. Expected: PASS.

### Task 3: Regression verification

**Files:**
- Verify: `nvim/lua/services/panel.lua`
- Verify: `nvim/lua/custom/task_runner.lua`

**Step 1: Run related services specs**

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/services_panel_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/task_runner_spec.lua" "+qa!"
```

Expected: all PASS.

**Step 2: Check whitespace**

Run: `git diff --check`

Expected: no errors.
