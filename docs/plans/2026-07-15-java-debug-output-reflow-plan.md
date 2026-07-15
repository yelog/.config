# Java Debug Output Reflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Route default Java Debug output into the normal Services log buffer so it reflows and renders ANSI styles like ordinary service output.

**Architecture:** Services runtime exposes narrow reset and append operations around its existing output renderer. Java Debug defaults to `internalConsole`, routes matching nvim-dap output events through the runtime, and preserves the existing integrated-terminal path when a project explicitly overrides `console`.

**Tech Stack:** Neovim Lua, `mfussenegger/nvim-dap`, Java Debug Adapter, Services runtime, headless Neovim Lua specs.

---

### Task 1: Specify runtime output operations

**Files:**
- Modify: `nvim/tests/services_runtime_spec.lua`

**Step 1: Write failing coverage**

Add a registered service with normal output, then assert that:

- `reset_output(key)` clears retained lines, restores the normal output buffer, and clears the terminal-output flag;
- `append_output(key, "stdout", chunk)` renders a logical line through the existing renderer;
- `append_output(key, "stderr", chunk)` keeps stderr input on its own stream while rendering to the same normal buffer;
- ANSI output continues to produce an extmark style span.

**Step 2: Run the spec to verify failure**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
```

Expected: failure because the runtime has no reset or append API.

### Task 2: Implement normal-output reset and append APIs

**Files:**
- Modify: `nvim/lua/services/runtime.lua:473-504`
- Test: `nvim/tests/services_runtime_spec.lua`

**Step 1: Add `reset_output(key)`**

Ensure the normal renderer, clear it, bind its `bufnr` as the active output, set `terminal_output=false`, emit `output_replaced`, and return the buffer number. Return `nil` for an unknown service.

**Step 2: Add `append_output(key, stream, data)`**

Ensure the renderer and pass the chunk through `renderer:push(stream, data)`. Return `false` for unknown services and `true` after accepting output.

**Step 3: Export the APIs**

Add both methods to the existing module forwarding list at the bottom of `services.runtime`.

**Step 4: Run the runtime spec**

Run the Task 1 command.

Expected: `services-runtime-tests: ok`.

### Task 3: Specify Java Debug internal-console routing

**Files:**
- Modify: `nvim/tests/java_debug_spec.lua`

**Step 1: Write failing coverage**

Extend existing Java Debug tests to assert:

- `launch_config` defaults to `console = "internalConsole"`;
- a project `.nvim/java-debug.json` can override it to `integratedTerminal`;
- `route_output(session, event)` accepts only an `internalConsole` service session;
- stdout and stderr DAP events appear in the service's normal renderer, with ANSI output retaining extmarks;
- non-service or integrated-terminal events are ignored.

**Step 2: Run the spec to verify failure**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/java_debug_spec.lua" "+qa!"
```

Expected: failure because the default console is still `integratedTerminal` and no output router exists.

### Task 4: Route nvim-dap output into Services logs

**Files:**
- Modify: `nvim/lua/custom/java_debug.lua:75-86`
- Modify: `nvim/lua/custom/java_debug.lua:353-403`
- Modify: `nvim/lua/custom/java_debug.lua:554-560`
- Test: `nvim/tests/java_debug_spec.lua`

**Step 1: Change the default console**

Set the base launch configuration to `internalConsole`. Keep `resolve_config` unchanged so project config remains the final override source.

**Step 2: Reset normal output at debug launch**

At the start of a Java Debug launch, call `runtime():reset_output(service.key)` instead of only ensuring an output buffer. This clears stale logs and keeps the normal `nofile` output bound until an explicit terminal fallback replaces it.

**Step 3: Add output routing**

Add `route_output(session, event)` that returns false unless the session has a service key and `console == "internalConsole"`. Route `event.category == "stderr"` to stderr; route all other categories to stdout via `runtime():append_output`.

Register an `dap.listeners.after.event_output.spring_services` listener in `M.setup`. It must only route events for `active_service_key`; being an `after` listener preserves nvim-dap's REPL output behavior.

**Step 4: Preserve terminal fallback**

Do not change `terminal_win_cmd`, terminal adoption, or archive code. They continue to handle project configurations that explicitly request `integratedTerminal`.

**Step 5: Run Java Debug tests**

Run the Task 3 command.

Expected: `java-debug-tests: ok`.

### Task 5: Verify reflow integration

**Files:**
- Verify: `nvim/lua/services/output.lua`
- Verify: `nvim/lua/services/runtime.lua`
- Verify: `nvim/lua/custom/java_debug.lua`
- Verify: `nvim/tests/services_zoom_spec.lua`

**Step 1: Run focused regression specs**

Run independently:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_zoom_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/java_debug_spec.lua" "+qa!"
```

Expected: all specs print their `*-tests: ok` markers.

**Step 2: Verify configuration and diff hygiene**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua +qa!
git diff --check
```

Expected: both commands exit successfully.

Do not commit unless explicitly requested by the user.
