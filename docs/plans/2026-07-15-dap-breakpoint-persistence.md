# DAP Breakpoint Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Persist all nvim-dap breakpoint types per project and restore them lazily across Neovim restarts.

**Architecture:** A custom module owns versioned per-project JSON catalogs. Buffer-local synchronization preserves unopened entries, while `BufReadPost` restores only the file being opened.

**Tech Stack:** Neovim Lua API, nvim-dap breakpoint API, JSON, headless Lua tests

---

### Task 1: Define storage and serialization behavior

**Files:**
- Create: `nvim/tests/dap_breakpoints_spec.lua`
- Create: `nvim/lua/custom/dap_breakpoints.lua`

**Steps:**

1. Write failing tests for root hashing, relative paths, full breakpoint fields, and project isolation.
2. Run `nvim --headless -u NONE -l tests/dap_breakpoints_spec.lua` and verify module loading fails.
3. Implement normalized root detection, versioned catalog loading, and atomic JSON writing.
4. Implement buffer synchronization that replaces only one file entry.
5. Run the test and verify serialization cases pass.

### Task 2: Restore breakpoints lazily and idempotently

**Files:**
- Modify: `nvim/tests/dap_breakpoints_spec.lua`
- Modify: `nvim/lua/custom/dap_breakpoints.lua`

**Steps:**

1. Add failing tests for advanced fields, duplicate prevention, invalid lines, and malformed JSON.
2. Implement `restore_buffer` with existing-breakpoint comparison and `dap.breakpoints.set`.
3. Add warning-only handling for corrupt catalogs.
4. Run the test and verify restore cases pass.

### Task 3: Integrate mappings and lifecycle

**Files:**
- Modify: `nvim/tests/dap_breakpoints_spec.lua`
- Modify: `nvim/lua/custom/dap_breakpoints.lua`
- Modify: `nvim/lua/plugins/lsp/dap.lua`

**Steps:**

1. Add failing tests for `BufReadPost` and `VimLeavePre` autocmd registration.
2. Implement setup, debounced save, and final synchronization.
3. Replace `<leader>db` with the persistence module's toggle wrapper while retaining existing DAP mappings and visual setup.
4. Run breakpoint and DAP style tests.

### Task 4: Regression verification

**Files:**
- Verify only

**Steps:**

1. Run all DAP, Java debug, and Services headless tests.
2. Run `git diff --check`.
3. Inspect the focused diff and confirm unrelated worktree changes remain intact.
