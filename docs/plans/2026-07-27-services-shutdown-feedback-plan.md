# Services Shutdown Feedback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Show a concise animated progress message while Services shuts down managed processes during Neovim exit.

**Architecture:** `services.lifecycle` coordinates the existing graceful wait and owns best-effort command-area feedback. Runtime and Java debug expose pending-unit counts so the lifecycle can report actual remaining service work without changing termination behavior.

**Tech Stack:** Lua, Neovim `nvim_echo` and `vim.wait`, headless Neovim tests.

---

### Task 1: Add Failing Lifecycle Feedback Tests

**Files:**
- Modify: `nvim/tests/services_lifecycle_spec.lua:55-96`

**Step 1: Add a pending-shutdown fixture**

Inject a `render_shutdown_status` callback and a deterministic `wait` function. Assert that graceful waiting renders a rotating Chinese status with remaining and total units, timeout renders force-close text, and completion clears feedback.

**Step 2: Run the lifecycle specification**

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_lifecycle_spec.lua" "+qa!"
```

Expected: FAIL because lifecycle has no feedback renderer.

### Task 2: Implement Pending Counts And Feedback

**Files:**
- Modify: `nvim/lua/services/runtime.lua:560-620,645-649`
- Modify: `nvim/lua/custom/java_debug.lua:485-515`
- Modify: `nvim/lua/services/lifecycle.lua:1-48`

**Step 1: Expose pending units**

Add `shutdown_pending_count()` to the runtime, counting services that still own a process, process group, or active status. Add the equivalent Java-debug method returning zero or one for its singleton session/build state.

**Step 2: Render feedback while waiting**

Add a protected default command-area renderer. During the current 20 ms wait predicate, calculate elapsed time and only update the spinner every 120 ms. Use an injected renderer in tests. Render force-close status before existing escalation and clear after the final completion check.

**Step 3: Run the lifecycle specification**

Run the command above. Expected: `services-lifecycle-tests: ok`.

### Task 3: Run Regression Checks

**Files:**
- Verify: `nvim/tests/services_*_spec.lua`
- Review: `nvim/lua/services/lifecycle.lua`, `nvim/lua/services/runtime.lua`, `nvim/lua/custom/java_debug.lua`

**Step 1: Run all service specifications**

```bash
for spec in nvim/tests/services_*_spec.lua; do nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/$spec" "+qa!" || exit 1; done
```

Expected: every specification reports `ok`.

**Step 2: Check whitespace and formatting**

```bash
stylua --check nvim/lua/services/lifecycle.lua nvim/lua/services/runtime.lua nvim/lua/custom/java_debug.lua nvim/tests/services_lifecycle_spec.lua
```

Expected: both commands exit successfully.
