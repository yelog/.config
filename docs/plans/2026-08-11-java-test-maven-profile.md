# Java Test Maven Profile Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Pass the services panel's selected Maven profile to Java tests run with `<leader>jt`.

**Architecture:** Keep Java test command discovery in `custom.task_runner`, but defer Maven profile insertion to the services runtime `prepare` hook. Resolve the profile at every start or rerun so tests never retain a stale selection.

**Tech Stack:** Neovim Lua, services runtime, Maven Surefire, headless Neovim specs

---

### Task 1: Specify profile-aware test preparation

**Files:**
- Modify: `nvim/tests/task_runner_spec.lua`

**Step 1: Add failing assertions**

Capture the registered Java test service definition and assert:

```lua
assert_equal({ "mvn", "-Pdev", "test" }, definition.prepare({ cmd = { "mvn", "test" } }, "dev"))
assert_equal({ "mvn", "test" }, definition.prepare({ cmd = { "mvn", "test" } }, nil))
```

Also assert that the first run and rerun pass the current profile obtained from
`services.state.get_profile(project_root)` to `runtime:restart()`.

**Step 2: Run the focused spec**

Run: `nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/task_runner_spec.lua" "+qa!"`

Expected: FAIL because test services currently have no `prepare` hook and restart without a profile.

### Task 2: Implement Maven profile insertion

**Files:**
- Modify: `nvim/lua/custom/task_runner.lua`

**Step 1: Add a test service prepare function**

Copy the service command, inspect its executable, and insert `-P<profile>` at
index 2 only when profile is a non-empty string and the executable is Maven.

**Step 2: Pass the current profile on every start**

Read `services.state.get_profile(project_root)` immediately before calling
`runtime:restart()` in both the initial Java test run and `<leader>xr` rerun.

**Step 3: Run the focused spec**

Run: `nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/task_runner_spec.lua" "+qa!"`

Expected: PASS.

### Task 3: Verify services integration

**Files:**
- Verify: `nvim/lua/custom/task_runner.lua`
- Verify: `nvim/lua/services/runtime.lua`

**Step 1: Run related specs**

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/task_runner_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/services_panel_spec.lua" "+qa!"
```

Expected: all specs PASS.

**Step 2: Verify the real command**

Build the `EmailUtilTest#testNormalEmail` task and invoke its `prepare` function
with `moss-mes-isg-dev`. Confirm the resulting argv contains exactly one
`-Pmoss-mes-isg-dev` immediately after `mvn`.

**Step 3: Check the diff**

Run: `git diff --check`

Expected: no whitespace errors.
