# Independent Services Runtime Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace Overseer-backed long-running services with a service-specific runtime that owns process lifecycle, responsive ANSI-colored logs, panel rendering, and Java Debug output binding.

**Architecture:** Move reusable discovery and persistence into `services.*`, run normal services through a non-PTY `vim.system()` runtime, and render output into normal buffers with ANSI spans stored as extmarks. Keep Overseer installed only for future generic tasks; the Services panel, service records, and Java Debug integration must not use Overseer task or sidebar internals.

**Tech Stack:** Lua, Neovim 0.11 APIs (`vim.system`, normal buffers, extmarks), fzf-lua, nvim-dap, jdtls, Nerd Font icons.

---

## Constraints

- Preserve the existing state file and schema at `stdpath("state")/overseer/spring-services.json` so stored profiles and selected service keys continue to work.
- Preserve `<leader>oo`, `<leader>os`, and `<leader>oa` behavior, but point them to the independent runtime.
- Do not modify or discard unrelated existing worktree changes.
- Do not commit unless the user explicitly requests a commit.
- Use normal non-PTY buffers for Spring Boot, npm, and custom service logs. A Java DAP session may use a terminal only while it is live; archive its final text to a normal buffer when it ends.

### Task 1: Establish Service State and Catalog Modules

**Files:**
- Create: `nvim/lua/services/state.lua`
- Create: `nvim/lua/services/catalog.lua`
- Create: `nvim/tests/services_state_catalog_spec.lua`
- Modify: `nvim/lua/overseer/service_state.lua` only after the new tests pass, by turning it into a temporary forwarding shim or leaving it untouched until Task 8
- Modify: `nvim/lua/overseer/service_catalog.lua` only after the new tests pass, by turning it into a temporary forwarding shim or leaving it untouched until Task 8

**Step 1: Write failing state and catalog tests**

Create a headless test that proves the new namespace preserves the current external behavior:

```lua
local state = require("services.state")
state.setup({ path = state_path })
assert(state.set_profile("/project/a", "dev"))
assert(vim.deep_equal({ "npm::web::dev" }, state.get_selected_services("/project/a")))

local catalog = require("services.catalog")
assert(catalog.get_type("springboot").label == "Spring Boot")
assert(catalog.key_from_definition({
  service_type = "springboot",
  metadata = { task_key = "module::com.example.App" },
}) == "springboot::module::com.example.App")
```

Include the existing state tests for atomic writes, corrupt JSON, cross-project preservation, duplicate keys, stale keys, and profile parsing. Do not depend on `require("overseer")` in this test.

**Step 2: Run the test and verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_state_catalog_spec.lua" "+qa!"
```

Expected: failure because `services.state` and `services.catalog` do not exist.

**Step 3: Port the minimal pure logic**

Move the state implementation without changing its persisted path or JSON fields. Implement the catalog API without referencing template or task types:

```lua
-- services/catalog.lua
M.get_type(service_type)
M.list_types()
M.key_from_definition(definition)
M.filter_selected(definitions, selected_keys)
M.replace_category(selected_keys, definitions, service_type, replacement_keys, clear_stale)
```

`key_from_definition` must use `definition.key` when present, then derive the current Spring, npm, and custom-service keys from definition metadata. Keep fallback type rendering and deterministic sorting.

**Step 4: Run the test and verify it passes**

Run the Task 1 command again.

Expected: `services-state-catalog-tests: ok`.

**Step 5: Review the scoped diff**

Run:

```bash
git diff --check
git diff -- nvim/lua/services/state.lua nvim/lua/services/catalog.lua nvim/tests/services_state_catalog_spec.lua
```

Expected: no whitespace errors and no unrelated changes in the diff.

### Task 2: Port Providers into a Service Definition Contract

**Files:**
- Create: `nvim/lua/services/providers/init.lua`
- Create: `nvim/lua/services/providers/springboot.lua`
- Create: `nvim/lua/services/providers/npm.lua`
- Create: `nvim/lua/services/providers/custom.lua`
- Create: `nvim/tests/services_providers_spec.lua`
- Read: `nvim/lua/custom/services.lua`

**Step 1: Write failing provider tests**

Use temporary Maven, Gradle, npm, and `.services.lua` fixtures. Assert a provider returns a service definition rather than an Overseer template:

```lua
assert_equal("springboot", definition.service_type)
assert_equal("com.example.order.OrderApplication", definition.metadata.main_class)
assert_equal({ "mvn", "spring-boot:run", "-Dspring-boot.run.mainClass=com.example.order.OrderApplication" }, definition.cmd)
assert(type(definition.prepare) == "function")
assert(type(definition.parse_line) == "function")
```

Cover Maven profile injection, multi-module metadata, npm package-manager command selection, stable keys, custom service metadata, and provider ordering.

**Step 2: Run the test and verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_providers_spec.lua" "+qa!"
```

Expected: failure because the provider modules do not exist.

**Step 3: Implement the common definition shape**

Each provider must return entries in this shape:

```lua
{
  key = "springboot::module::com.example.App",
  name = "App",
  service_type = "springboot",
  cmd = { "mvn", "spring-boot:run", "..." },
  cwd = "/project",
  env = nil,
  metadata = { project_root = "/project", main_class = "com.example.App" },
  restart = { auto = false, delay = 3, max_attempts = 3 },
  health_check = nil,
  color_policy = "provider",
  prepare = function(definition, profile) return command end,
  parse_line = function(metadata, line) return changed_metadata end,
}
```

Reuse the current scanning and parsing logic, but remove component constructors, `on_*` hooks, `overseer.TAG`, and template builders. `services.providers.discover(root)` must concatenate, normalize, and sort all provider entries.

**Step 4: Run the test and verify it passes**

Run the Task 2 command again.

Expected: `services-provider-tests: ok`.

**Step 5: Run the existing discovery regression test**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/overseer_services_spec.lua" "+qa!"
```

Expected: existing tests remain green until the old modules are removed in Task 8.

### Task 3: Build a Normal-Buffer ANSI Output Renderer

**Files:**
- Create: `nvim/lua/services/output.lua`
- Create: `nvim/tests/services_output_spec.lua`

**Step 1: Write failing output tests**

Test exact text and extmark behavior using a normal `nofile` buffer:

```lua
local output = require("services.output").new({ limit = 3 })
output:push("stdout", "\27[31mred")
output:push("stdout", " text\27[0m\n")
vim.wait(100, function() return vim.api.nvim_buf_line_count(output.bufnr) == 1 end)

assert_equal({ "red text" }, vim.api.nvim_buf_get_lines(output.bufnr, 0, -1, false))
assert(#vim.api.nvim_buf_get_extmarks(output.bufnr, output.namespace, 0, -1, {}) > 0)
```

Add coverage for split SGR sequences, stderr state isolated from stdout state, reset codes, 16-color, 256-color, RGB color spans, malformed sequences, partial non-ANSI lines, and FIFO trimming with retained extmarks.

**Step 2: Run the test and verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_output_spec.lua" "+qa!"
```

Expected: failure because `services.output` does not exist.

**Step 3: Implement incremental ANSI decoding and buffered writes**

Expose a small renderer object:

```lua
local output = M.new({ limit = 10000, name = "OrdersApplication" })
output:push("stdout", chunk)
output:push("stderr", chunk)
output:clear()
output:archive_from_buffer(terminal_bufnr)
output:dispose()
```

Keep a decoder state and unfinished line per stream. Decode CSI SGR into stripped text plus byte-based spans. Batch buffer changes through `vim.schedule`, append text with `nvim_buf_set_lines`, and attach highlight spans through one dedicated namespace. Cache generated highlight groups by style/color tuple. Unsupported CSI sequences must be removed without raising.

When trimming oldest lines, delete them with `nvim_buf_set_lines`; do not manually repair extmarks because Neovim tracks them. Set output buffer options to `buftype=nofile`, `bufhidden=hide`, `buflisted=false`, `swapfile=false`, and `modifiable=false` outside writes.

**Step 4: Run the test and verify it passes**

Run the Task 3 command again.

Expected: `services-output-tests: ok`.

**Step 5: Add an explicit resize regression test**

Open the normal output buffer in a narrow window, assert `wrap` and `linebreak` are enabled, move it into a wider floating window, and assert the buffer text and ANSI extmarks survive unchanged. This verifies the design does not depend on terminal scrollback reflow.

### Task 4: Implement the Service Runtime and Lifecycle State Machine

**Files:**
- Create: `nvim/lua/services/runtime.lua`
- Create: `nvim/tests/services_runtime_spec.lua`
- Read: `nvim/lua/overseer/component/service/lifecycle.lua`

**Step 1: Write failing runtime tests with an injected process factory**

The runtime must be testable without starting Maven. Inject a fake spawn function that records callbacks and returns a fake process with `kill`:

```lua
local runtime = require("services.runtime").new({
  spawn = function(cmd, opts, on_exit)
    return { pid = 42, kill = function() end }, on_exit, opts
  end,
})
local service = runtime:register(definition)
service:subscribe(function(event) events[#events + 1] = event end)
service:start()
assert_equal("RUNNING", service.status)
```

Cover state transitions, stdout-to-parser metadata updates, start failure, manual stop not restarting, failure restart, restart-attempt cap, stale exit callbacks after restart, disposal, health timer cleanup, and output rebinding.

**Step 2: Run the test and verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
```

Expected: failure because `services.runtime` does not exist.

**Step 3: Implement explicit records and public operations**

Use one record per stable service key. The record must expose read-only definition fields plus mutable `status`, `metadata`, `output`, `process`, and `generation` fields. Implement:

```lua
runtime:reconcile(root, definitions, selected_keys)
runtime:get(key)
runtime:list(root)
runtime:start(key)
runtime:stop(key)
runtime:restart(key)
runtime:dispose(key)
runtime:subscribe(callback)
runtime:replace_output(key, bufnr, opts)
```

The default spawn adapter calls `vim.system(command, { cwd = cwd, env = env, text = true, stdout = callback, stderr = callback }, on_exit)`. Schedule callback work before touching buffers. Increment generation before every start and ignore callbacks whose captured generation is no longer current.

Use `STOPPING`, `RUNNING`, `FAILED`, `STOPPED`, and `DEBUGGING` states rather than reusing Overseer status strings internally. Convert to panel display state in one helper. Start health checks only while the matching generation is live. Stop sends TERM, schedules a bounded escalation only if the same process and generation remain live, and cleans all timers on exit or disposal.

**Step 4: Run the test and verify it passes**

Run the Task 4 command again.

Expected: `services-runtime-tests: ok`.

**Step 5: Run an actual short-lived process smoke test**

Add a separate assertion using `vim.system({ "sh", "-c", "printf '\\033[32mok\\033[0m\\n'" })` through the real default adapter. Assert stripped text, a color extmark, and a terminal completion state.

### Task 5: Implement the Independent Services Panel

**Files:**
- Create: `nvim/lua/services/panel.lua`
- Create: `nvim/lua/plugins/panel/services.lua`
- Create: `nvim/tests/services_panel_spec.lua`
- Read: `nvim/lua/plugins/panel/overseer.lua`

**Step 1: Write failing view and controller tests**

Keep UI logic testable by exposing pure helpers for row rendering and winbar text:

```lua
assert_equal("SERVICES  0 selected  [a add]", panel.winbar_text({ selected = {}, services = {} }))
assert_equal("SPRING + NPM SERVICES  2 selected  [a manage]", panel.winbar_text({
  selected = { "springboot::orders", "npm::web::dev" },
  services = services,
}))
```

Use a fake runtime to assert list rendering updates when it emits service events, changing focused service replaces the log buffer in place, and the output window has `wrap=true` and `linebreak=true`.

**Step 2: Run the test and verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_panel_spec.lua" "+qa!"
```

Expected: failure because `services.panel` does not exist.

**Step 3: Implement bottom list/output layout without Overseer internals**

Create the list and output splits directly with Neovim APIs. The panel owns its buffers and window IDs, tracks project root by tab, and subscribes once to runtime events. Render rows with the current icon, type icon, name, and detail ordering. Use a focused-key field instead of an Overseer cursor-to-task mapping.

Implement panel-local keys:

```lua
a  -- manage service selection
p  -- choose Spring profile
u  -- open detected URL
s  -- start selected service
r  -- restart selected service
S  -- stop selected service
gp -- toggle output preview if retained
```

Reuse the current two-stage `vim.ui.select` plus `fzf-lua` multi-select UX, but call `services.catalog`, `services.state`, and `runtime:reconcile`. Persist selection before changing records. Running or debugging deselected services remain visible until manually stopped and disposed.

**Step 4: Register the plugin entry point**

`nvim/lua/plugins/panel/services.lua` initializes state, providers, runtime, and panel, then registers `:ServicesToggle` and `:ServicesOpen`. It must not call `require("overseer")`.

**Step 5: Run the tests and verify they pass**

Run the Task 5 command and the prior service tests.

Expected: panel tests pass and no test requires `overseer.task_list.sidebar`.

### Task 6: Decouple Java Debug from Overseer Tasks

**Files:**
- Modify: `nvim/lua/custom/java_debug.lua`
- Modify: `nvim/tests/java_debug_spec.lua`
- Modify: `nvim/lua/services/runtime.lua`

**Step 1: Write failing service-record tests**

Replace task-shaped fixtures with service-record fixtures:

```lua
local service = {
  key = "springboot::orders",
  name = "OrderApplication",
  metadata = {
    project_root = "/repo",
    project_name = "order-service",
    main_class = "com.example.OrderApplication",
  },
}
assert_equal("Debug OrderApplication", java_debug.launch_config(service).name)
```

Assert Java Debug calls a runtime-owned output binding method rather than setting `strategy.bufnr`, `vim.b.overseer_task`, or `overseer.task_list.touch`.

**Step 2: Run the test and verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/java_debug_spec.lua" "+qa!"
```

Expected: assertions still observe task strategy mutation.

**Step 3: Replace task coupling with runtime operations**

Change Java Debug public methods to accept a service key or record. Fetch state through `services.runtime`. Replace `touch`, `ensure_output_buffer`, `adopt_output_buffer`, and strategy mutation with runtime methods:

```lua
runtime:ensure_output(service_key)
runtime:replace_output(service_key, terminal_buf, { terminal = true })
runtime:archive_terminal_output(service_key, terminal_buf)
runtime:set_debugging(service_key, true)
```

Keep the existing jdtls command sequencing, project configuration merge, and active-session protection. On DAP close, archive terminal text as a normal plain-text output buffer and clear debugging through the runtime. Do not claim color preservation for this archive.

**Step 4: Run the test and verify it passes**

Run the Task 6 command again.

Expected: `java-debug-tests: ok`, with no references to `task.strategy`, `overseer_task`, or `overseer.task_list` in `custom/java_debug.lua`.

**Step 5: Verify direct DAP keymaps remain valid**

Run:

```bash
nvim --headless "+lua require('lazy').load({ plugins = { 'nvim-dap' } })" "+qa!"
```

Expected: no Lua errors from `<leader>dt` or Java Debug setup.

### Task 7: Rewire Keymaps and Remove Service-Specific Overseer Configuration

**Files:**
- Modify: `nvim/lua/key-map.lua`
- Modify: `nvim/lua/plugins/panel/overseer.lua`
- Delete: `nvim/lua/overseer/component/service/lifecycle.lua`
- Delete: `nvim/lua/overseer/component/service/springboot.lua`
- Delete: `nvim/lua/overseer/component/service/npm.lua`
- Delete: `nvim/lua/overseer/template/springboot.lua`
- Delete: `nvim/lua/overseer/template/npm.lua`
- Delete: `nvim/lua/overseer/template/service.lua`
- Delete or replace after all callers migrate: `nvim/lua/overseer/service_state.lua`
- Delete or replace after all callers migrate: `nvim/lua/overseer/service_catalog.lua`
- Modify: `nvim/tests/overseer_services_spec.lua`

**Step 1: Write a failing integration loading test**

Create a test that loads the Services plugin entry point without loading or mocking Overseer and asserts that the public commands exist:

```lua
require("services.panel").setup()
assert(vim.fn.exists(":ServicesToggle") == 2)
assert(vim.fn.exists(":ServicesOpen") == 2)
```

**Step 2: Run the test and verify it fails**

Run the new test headlessly.

Expected: failure until the plugin and mappings no longer depend on `OverseerToggle`.

**Step 3: Switch public entry points**

Update mappings:

```lua
map("n", "<leader>oo", function() vim.cmd("ServicesToggle") end, { desc = "Toggle services panel" })
map("n", "<leader>os", function() require("services.runtime").stop_all() end, { desc = "Stop all services" })
map("n", "<leader>oa", function() require("services.runtime").start_all() end, { desc = "Start all services" })
```

Reduce `plugins/panel/overseer.lua` to generic Overseer setup only, or remove its service-specific configuration entirely if no generic config is needed. Delete old service templates and components only after all `services.*` tests and the Java Debug migration pass. Rename or replace the old Overseer service test so it no longer loads old modules.

**Step 4: Run all affected tests**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_state_catalog_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_providers_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_output_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_runtime_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/services_panel_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/java_debug_spec.lua" "+qa!"
```

Expected: all tests pass without requiring any service-facing `overseer.*` module.

### Task 8: Validate Real Process, Zoom, and Shutdown Behavior

**Files:**
- Create: `nvim/tests/services_integration_spec.lua`
- Modify if integration reveals a real defect: the smallest relevant `nvim/lua/services/*.lua` file

**Step 1: Add an opt-in integration test**

Use small shell fixture scripts to cover normal output, ANSI output, slow partial output, nonzero exit, and signal termination. Keep it opt-in if CI lacks a POSIX shell.

**Step 2: Test normal log reflow**

Open a service output buffer in a narrow split, write retained lines, open the same buffer through `Snacks.zen.zoom()`, and assert the buffer remains normal (`buftype=nofile`) with `wrap=true`. Assert historical lines are still present and extmarks remain attached.

**Step 3: Test process stop semantics against representative services**

Manually verify in a Spring Boot Maven project and an npm project:

- launch and wait for ready state;
- use `S` and verify the actual child process stops;
- use `r` and verify stale output does not leak into the new generation;
- trigger a failure and verify bounded auto-restart;
- zoom a populated normal log and verify historical wrapping changes with width;
- start Java Debug, verify the output position is reused, terminate, and verify its plain archive is readable and reflowable.

**Step 4: Run formatting and startup checks**

Run:

```bash
stylua --check nvim/lua/services nvim/lua/custom/java_debug.lua nvim/lua/key-map.lua nvim/lua/plugins/panel/services.lua nvim/lua/plugins/panel/overseer.lua nvim/tests
git diff --check
nvim --headless "+lua require('lazy').load({ plugins = { 'overseer.nvim', 'fzf-lua', 'nvim-dap' } })" "+qa!"
```

Expected: no formatting, whitespace, or startup errors.

**Step 5: Review before any commit**

Run:

```bash
git status --short
```

Expected: only the independent Services runtime migration files are changed. Do not create a commit unless explicitly requested by the user.
