# Services Log Clear Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `c` action to clear a service's standard in-memory log from either Services pane.

**Architecture:** Introduce a dedicated runtime `clear_output` operation that delegates to the existing output renderer and emits `output_cleared`. The panel maps `c` in list and standard output buffers, then resets follow UI state when it receives that event.

**Tech Stack:** Neovim Lua, `vim.api`, headless Neovim Lua specifications.

---

### Task 1: Cover and expose runtime log clearing

**Files:**
- Modify: `nvim/tests/services_runtime_spec.lua`
- Modify: `nvim/lua/services/runtime.lua:491-508`

**Step 1: Write the failing test**

Add a service, append a completed output line, call `runtime:clear_output(key)`,
and assert that the original output buffer remains assigned, contains no lines,
and publishes an `output_cleared` event for that service.

**Step 2: Run the test to verify it fails**

Run: `nvim --headless -u NONE -l nvim/tests/services_runtime_spec.lua`

Expected: FAIL because `clear_output` is missing.

**Step 3: Write minimal implementation**

Add `Runtime:clear_output(key)`. It must return `false` for an unknown service,
otherwise call `_ensure_output(service):clear()`, keep `output_bufnr` and
`terminal_output` unchanged, emit `output_cleared`, and return `true`. Add it to
the module-level delegating method list.

**Step 4: Run the test to verify it passes**

Run: `nvim --headless -u NONE -l nvim/tests/services_runtime_spec.lua`

Expected: `services-runtime-tests: ok`.

### Task 2: Add panel clear actions and synchronization

**Files:**
- Modify: `nvim/tests/services_panel_spec.lua`
- Modify: `nvim/lua/services/panel.lua:101-113`
- Modify: `nvim/lua/services/panel.lua:502-549`
- Modify: `nvim/lua/services/panel.lua:793-829`

**Step 1: Write the failing tests**

Extend the panel specification to append output, pause follow, invoke `c` from

**Step 2: Run the test to verify it fails**

Run: `nvim --headless -u NONE -l nvim/tests/services_panel_spec.lua`

Expected: FAIL because neither mapping nor `output_cleared` handling exists.

**Step 3: Write minimal implementation**

Add `c` to the help items. Add a panel helper that rejects terminal output with
a warning and otherwise calls `runtime:clear_output`. Bind it in the list buffer
for the cursor-selected service and in each normal output buffer when it is
shown. Handle `output_cleared` without rerendering the list: reset the matching
service's output state to follow, clear unread/view, and update the winbar.

**Step 4: Run the test to verify it passes**

Run: `nvim --headless -u NONE -l nvim/tests/services_panel_spec.lua`

Expected: `services-panel-tests: ok`.

### Task 3: Run the focused regression suite

**Files:**
- Verify: `nvim/tests/services_output_spec.lua`
- Verify: `nvim/tests/services_runtime_spec.lua`
- Verify: `nvim/tests/services_panel_spec.lua`

**Step 1: Run all focused specifications**

Run: `for test in nvim/tests/services_output_spec.lua nvim/tests/services_runtime_spec.lua nvim/tests/services_panel_spec.lua; do nvim --headless -u NONE -l "$test" || exit 1; done`

Expected: all three specs print their `: ok` marker and exit with status 0.

**Step 2: Inspect the final diff**

Run: `git diff -- nvim/lua/services/runtime.lua nvim/lua/services/panel.lua nvim/tests/services_runtime_spec.lua nvim/tests/services_panel_spec.lua docs/plans/2026-07-27-services-log-clear-design.md docs/plans/2026-07-27-services-log-clear.md`

Expected: the diff contains only the clear-log runtime API, panel interaction,
coverage, and supporting documentation.
