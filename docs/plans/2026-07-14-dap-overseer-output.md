# DAP and Overseer Output Reuse Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reuse the Overseer Services output pane for Java DAP process logs without opening a new split.

**Architecture:** A Java-specific nvim-dap terminal callback creates the terminal buffer and adopts it as the active Overseer task's output buffer. Existing windows showing the old task output are switched in place; when no output window is open, the terminal remains hidden until Services displays it.

**Tech Stack:** Neovim Lua, nvim-dap, Overseer.nvim, nvim-jdtls

---

### Task 1: Test output-buffer adoption

**Files:**
- Modify: `nvim/tests/java_debug_spec.lua`

**Steps:**
1. Add a fake task strategy and visible window fixture.
2. Assert that adoption updates the strategy buffer and visible window in place.
3. Assert that adoption succeeds without a visible window.
4. Run the focused test and verify it fails before implementation.

### Task 2: Implement terminal reuse

**Files:**
- Modify: `nvim/lua/custom/java_debug.lua`

**Steps:**
1. Add a testable output-buffer adoption function.
2. Register `dap.defaults.java.terminal_win_cmd` during Java debug setup.
3. Create a scratch buffer, adopt it for the active service, and return the existing output window when available.
4. Preserve current DAP lifecycle ownership and cleanup behavior.

### Task 3: Verify behavior and documentation

**Files:**
- Modify: `nvim/README.md`

**Steps:**
1. Document that debug logs replace the current service output in place.
2. Run focused tests, Overseer tests, StyLua, `git diff --check`, and headless startup.
3. Verify that the callback creates no additional window.
