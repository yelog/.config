# Java Nearest Test Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `<leader>jt` run the Java test method under the cursor in Maven multi-module projects such as moss-cloud.

**Architecture:** Extend the existing `custom.task_runner` Maven command builder rather than adding a second Java test runner. Resolve the reactor root and nearest module POM, build a Surefire method target, and register Java tests with the services runtime so the existing services panel owns execution and output.

**Tech Stack:** Neovim Lua, Maven Surefire, Overseer, headless Neovim specs

---

### Task 1: Specify Maven reactor command generation

**Files:**
- Modify: `nvim/tests/task_runner_spec.lua`

**Step 1: Add a failing reactor test**

Create a Java nearest-test context with reactor root `/workspace`, module POM
`/workspace/services/message/pom.xml`, and target method `EmailUtilTest#testNormalEmail`.
Assert that the command runs from `/workspace` and contains:

```lua
{
  "mvn",
  "-pl", "services/message",
  "-am",
  "-Dmoss.skipTests=false",
  "-Dsurefire.failIfNoSpecifiedTests=false",
  "-Dtest=com.lenovo.moss.EmailUtilTest#testNormalEmail",
  "test",
}
```

**Step 2: Run the spec and verify failure**

Run: `nvim --headless -u NONE "+luafile nvim/tests/task_runner_spec.lua" "+qa!"`

Expected: FAIL because the current runner executes at the nearest build root and omits reactor/MOSS arguments.

### Task 2: Implement reactor-aware Java Maven tests

**Files:**
- Modify: `nvim/lua/custom/task_runner.lua:52-95`

**Step 1: Resolve Maven execution context**

Use `custom.maven_profiles.find_project_root()` for the reactor root and
`find_nearest_pom()` for the selected module. Derive a normalized module path
relative to the reactor root. Preserve test-injected Maven paths for deterministic specs.

**Step 2: Build the nearest/file command**

For selected Maven tests, construct argv in this order:

```lua
{ executable, "-pl", module, "-am", "-Dmoss.skipTests=false",
  "-Dsurefire.failIfNoSpecifiedTests=false", "-Dtest=" .. target, "test" }
```

Omit `-pl` and `-am` when the nearest POM is the reactor root POM. For all Maven tests, include only `-Dmoss.skipTests=false` before `test`.

**Step 3: Run the focused spec**

Run: `nvim --headless -u NONE "+luafile nvim/tests/task_runner_spec.lua" "+qa!"`

Expected: PASS.

### Task 3: Bind the Java shortcut and services output

**Files:**
- Modify: `nvim/lua/key-map.lua`
- Modify: `nvim/lua/plugins/lsp/jdtls.lua:72-74`
- Modify: `nvim/lua/services/catalog.lua`
- Modify: `nvim/tests/lsp_topology_spec.lua`

**Step 1: Add a failing keymap assertion**

Assert that the global keymap maps `<leader>jt` to
`require("custom.task_runner").run("nearest")`, and that Java task definitions
expose their class/method name and project root to the services panel.

**Step 2: Run the spec and verify failure**

Run: `nvim --headless -u NONE "+luafile nvim/tests/lsp_topology_spec.lua" "+qa!"`

Expected: FAIL because `<leader>jt` currently only displays a warning.

**Step 3: Replace the mapping**

Call the existing task runner from a global mapping, remove the buffer-local
mapping, register Java test commands as transient `test` services, open and
focus the services panel, and leave `<leader>jT` unchanged because Java test
debugging remains incompatible.

**Step 4: Run the focused specs**

Run:

```bash
nvim --headless -u NONE "+luafile nvim/tests/task_runner_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile nvim/tests/lsp_topology_spec.lua" "+qa!"
```

Expected: both PASS.

### Task 4: Verify the Neovim configuration

**Files:**
- Verify: `nvim/lua/custom/task_runner.lua`
- Verify: `nvim/lua/plugins/lsp/jdtls.lua`

**Step 1: Run all native Neovim specs**

Run: `for test in nvim/tests/*_spec.lua; do nvim --headless -u NONE "+luafile ${test}" "+qa!" || exit 1; done`

Expected: all specs PASS.

**Step 2: Check the final diff**

Run: `git diff --check && git diff -- nvim/lua/custom/task_runner.lua nvim/lua/plugins/lsp/jdtls.lua nvim/tests/task_runner_spec.lua nvim/tests/lsp_topology_spec.lua docs/plans/2026-08-11-java-nearest-test-design.md docs/plans/2026-08-11-java-nearest-test.md`

Expected: no whitespace errors and only the intended Java test workflow changes.
