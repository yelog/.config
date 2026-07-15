# Services Shutdown Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stop every managed Services process tree and active Java Debug session during a normal Neovim exit.

**Architecture:** POSIX service commands become detached process-group leaders and runtime process handles signal the group instead of only the top-level PID. A small lifecycle module coordinates `VimLeavePre`, runtime shutdown, and Java Debug cleanup through one grace period before force escalation.

**Tech Stack:** Neovim Lua, `vim.system`, libuv (`vim.uv.kill`), nvim-dap, headless Neovim Lua specs.

---

### Task 1: Add process-group runtime coverage

**Files:**
- Modify: `nvim/tests/services_runtime_spec.lua`

**Step 1: Write failing unit tests**

Add a fake process exposing `pid` and `kill`, then assert that runtime shutdown:

- sends `15` to every active process;
- cancels restart-pending records without restarting them;
- sends `9` only to records still active after the grace period;
- ignores stale exit callbacks after shutdown begins.

Add a real smoke test that starts `sh -c 'sleep 30 & wait'`, invokes the runtime shutdown API with a short grace period, and verifies the tracked shell and its `sleep` child no longer exist.

**Step 2: Run the spec to verify failure**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
```

Expected: failure because process-group shutdown APIs do not exist.

### Task 2: Implement process-group lifecycle in the runtime

**Files:**
- Modify: `nvim/lua/services/runtime.lua:24-42`
- Modify: `nvim/lua/services/runtime.lua:140-223`
- Modify: `nvim/lua/services/runtime.lua:380-511`

**Step 1: Add detached process wrapper**

Spawn POSIX commands with `vim.system(..., { detach = true })`. Return a wrapper that retains the system object and routes `kill(signal)` to `vim.uv.kill(-pid, signal)`. If group signalling is unavailable or fails, fall back to the system object's direct `kill` method.

**Step 2: Add runtime shutdown phases**

Expose minimal public methods:

- `begin_shutdown()` marks the runtime as shutting down, cancels restart and health-check timers, and sends `SIGTERM` to managed process groups;
- `is_shutdown_complete()` reports whether any managed process remains;
- `force_shutdown()` sends `SIGKILL` to remaining groups and clears pending restart state.

Guard `_schedule_restart()` so no restart can be scheduled while shutdown is active. Keep existing manual stop, restart, and disposal paths unchanged except that they now use group-aware `kill()`.

**Step 3: Run the runtime spec**

Run the Task 1 command.

Expected: `services-runtime-tests: ok`.

### Task 3: Add coordinated exit lifecycle

**Files:**
- Create: `nvim/lua/services/lifecycle.lua`
- Modify: `nvim/lua/plugins/panel/overseer.lua:3-13`
- Create: `nvim/tests/services_lifecycle_spec.lua`

**Step 1: Write failing lifecycle tests**

Use injected fake runtime and Java Debug dependencies to verify that a lifecycle shutdown:

- starts runtime and Java Debug shutdown before waiting;
- waits no longer than the configured grace period;
- skips force escalation when both complete in time;
- force-stops remaining runtime and Java Debug work after the grace period;
- registers exactly one `VimLeavePre` autocmd when setup runs repeatedly.

**Step 2: Implement `services.lifecycle`**

Create a coordinator with `setup(runtime)` and `shutdown(runtime, opts)`. It lazily loads Java Debug, begins both shutdown paths, runs `vim.wait` for the shared three-second deadline, then calls force methods only for incomplete work. Register it once from the existing Services initialization path.

**Step 3: Run lifecycle tests**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_lifecycle_spec.lua" "+qa!"
```

Expected: `services-lifecycle-tests: ok`.

### Task 4: Add Java Debug exit cleanup

**Files:**
- Modify: `nvim/lua/custom/java_debug.lua:272-390`
- Modify: `nvim/tests/java_debug_spec.lua`

**Step 1: Write failing Java Debug tests**

Add dependency-injected tests for a graceful shutdown request and a forced terminal-job stop. Verify that an in-flight build is killed, DAP termination is requested with `terminateDebuggee = true`, and a known terminal job PID is force-killed after the grace period.

**Step 2: Implement shutdown helpers**

Expose `begin_shutdown()` and `force_shutdown()` without changing ordinary user-triggered `terminate()` behavior. The graceful path cancels the build and requests DAP termination. The forced path stops the active integrated-terminal job and sends `SIGKILL` to its PID if still present. Provide an `is_shutdown_complete()` predicate for the lifecycle coordinator.

**Step 3: Run Java Debug tests**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/java_debug_spec.lua" "+qa!"
```

Expected: `java-debug-tests: ok`.

### Task 5: Verify integration and configuration loading

**Files:**
- Verify: `nvim/lua/services/runtime.lua`
- Verify: `nvim/lua/services/lifecycle.lua`
- Verify: `nvim/lua/custom/java_debug.lua`
- Verify: `nvim/lua/plugins/panel/overseer.lua`

**Step 1: Run all Services and Java Debug specs**

Run each command independently:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_output_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_lifecycle_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_panel_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/java_debug_spec.lua" "+qa!"
```

Expected: every spec prints its `*-tests: ok` marker.

**Step 2: Validate startup and diff hygiene**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua +qa!
git diff --check
```

Expected: both commands exit successfully.

Do not commit unless explicitly requested by the user.
