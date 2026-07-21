# Services Log Follow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the Services output pane follow live logs by default while preserving historical log searches until the user returns to the tail.

**Architecture:** The ANSI renderer emits one post-render batch notification after each scheduled buffer update. The runtime forwards it as a dedicated service event, and the panel owns per-service follow state for its output window. The panel tails only a stateful following view, pauses on log navigation or search, and resumes when the cursor reaches the final retained line.

**Tech Stack:** Neovim 0.11 Lua API, `vim.schedule`, `nvim_win_call`, normal `nofile` buffers, buffer extmarks, headless Lua tests.

---

### Task 1: Report completed output render batches

**Files:**
- Modify: `nvim/lua/services/output.lua:261-323,427-447`
- Modify: `nvim/tests/services_output_spec.lua:39-123`

**Step 1: Write the failing renderer callback test**

Add a second renderer fixture with `on_render` and verify that one scheduled
batch exposes the appended count, retained count, and trimmed count:

```lua
local batches = {}
local notified = require("services.output").new({
  limit = 3,
  on_render = function(batch) batches[#batches + 1] = batch end,
})

notified:push("stdout", "one\ntwo\n")
assert(vim.wait(500, function() return #batches == 1 end), "render callback should run")
assert_equal(2, batches[1].appended, "batch should report appended lines")
assert_equal(2, batches[1].line_count, "batch should report retained lines")
assert_equal(0, batches[1].trimmed, "initial batch should not trim")

notified:push("stdout", "three\nfour\n")
assert(vim.wait(500, function() return #batches == 2 end), "second render callback should run")
assert_equal(2, batches[2].appended, "second batch should report appended lines")
assert_equal(3, batches[2].line_count, "retention should cap the rendered buffer")
assert_equal(1, batches[2].trimmed, "batch should report evicted lines")
notified:dispose()
```

**Step 2: Run the focused test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_output_spec.lua" "+qa!"
```

Expected: the callback assertions fail because `Output.new()` does not retain or
invoke `on_render`.

**Step 3: Implement the minimal post-render callback**

In `Output:_render_pending()`, record `trimmed` before deleting overflow. After
the buffer content, extmarks, `line_count`, and trimming are complete, invoke a
new optional callback once:

```lua
local trimmed = math.max(0, self.line_count - self.limit)
if trimmed > 0 then
  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, 0, trimmed, false, {})
  vim.bo[self.bufnr].modifiable = false
  self.line_count = self.line_count - trimmed
end

if self.on_render then
  self.on_render({
    bufnr = self.bufnr,
    appended = #pending,
    line_count = self.line_count,
    trimmed = trimmed,
  })
end
```

Store `opts.on_render` on the object returned by `M.new()`. Do not notify for an
empty `pending_lines` queue or make `clear()` produce a synthetic output batch.

**Step 4: Run the focused test to verify it passes**

Run the Task 1 command again.

Expected: `services-output-tests: ok`.

**Step 5: Commit the renderer boundary**

```bash
git add nvim/lua/services/output.lua nvim/tests/services_output_spec.lua
git commit -m "feat(services): report rendered output batches"
```

### Task 2: Forward render batches through the service runtime

**Files:**
- Modify: `nvim/lua/services/runtime.lua:92-106`
- Modify: `nvim/tests/services_runtime_spec.lua:53-67`

**Step 1: Write the failing runtime event test**

Subscribe to the existing runtime before sending output, collect full event
objects, and assert that a normal rendered line produces an `output_rendered`
event for the correct service with the renderer payload:

```lua
local rendered_event
runtime:subscribe(function(event)
  if event.type == "output_rendered" then rendered_event = event end
end)

assert(runtime:append_output(service.key, "stdout", "follow batch\n"),
  "runtime should accept output for rendered-event coverage")
assert(vim.wait(500, function() return rendered_event ~= nil end),
  "runtime should forward the completed renderer batch")
assert_equal(service, rendered_event.service, "render event should retain its service")
assert_equal(1, rendered_event.detail.appended, "render event should expose appended lines")
assert_equal(service.output.bufnr, rendered_event.detail.bufnr, "render event should expose its buffer")
```

**Step 2: Run the focused test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_runtime_spec.lua" "+qa!"
```

Expected: the wait times out because the runtime only forwards lifecycle and
metadata events today.

**Step 3: Wire the renderer callback into the runtime event stream**

Pass `on_render` when `_ensure_output(service)` constructs `services.output`:

```lua
on_render = function(detail)
  self:_emit(service, "output_rendered", detail)
end,
```

Keep `on_line` unchanged so provider parsers still consume complete log lines.
Do not translate an output batch into `updated`, because that event causes
service metadata rendering and is not a log-view notification.

**Step 4: Run the focused test to verify it passes**

Run the Task 2 command again.

Expected: `services-runtime-tests: ok`.

**Step 5: Commit the runtime event**

```bash
git add nvim/lua/services/runtime.lua nvim/tests/services_runtime_spec.lua
git commit -m "feat(services): emit output render events"
```

### Task 3: Add stateful follow and pause behavior to the panel

**Files:**
- Modify: `nvim/lua/services/panel.lua:29-61,159-179,410-458,607-636`
- Modify: `nvim/tests/services_panel_spec.lua:69-145`

**Step 1: Write the failing panel behavior tests**

Add local test helpers that inspect the output window in its own context:

```lua
local function output_cursor(winid)
  return vim.api.nvim_win_get_cursor(winid)
end

local function at_tail(winid)
  return vim.api.nvim_win_call(winid, function()
    return vim.api.nvim_win_get_cursor(0)[1] == vim.api.nvim_buf_line_count(0)
  end)
end
```

After focusing `orders`, append enough lines to exceed the output height. Assert
that the output window reaches the tail while the current window remains the
service list. Then move the output cursor to its first log line and execute
`CursorMoved`; append another line and assert all of the following:

```lua
assert_equal(false, instance.output_states[orders.key].following, "older cursor position should pause follow")
assert_equal({ 1, 0 }, output_cursor(instance.output_win), "paused output should keep its cursor")
assert_equal(1, instance.output_states[orders.key].unseen_lines, "paused output should count new lines")
assert(vim.wo[instance.output_win].winbar:find("PAUSED", 1, true), "paused state should be visible")
```

Record `nvim_buf_get_changedtick(instance.list_bufnr)` before the paused append
and assert that it is unchanged afterward. This proves `output_rendered` does
not re-render the Services list.

Simulate a search start with:

```lua
vim.api.nvim_set_current_win(instance.output_win)
vim.api.nvim_exec_autocmds("CmdlineEnter", { pattern = "/", modeline = false })
assert_equal(false, instance.output_states[orders.key].following, "search should pause follow before input")
```

Finally, move the output cursor to `nvim_buf_line_count(orders.output.bufnr)`,
execute `CursorMoved`, append one more line, and assert that the state is
following, its unread count is zero, the cursor reaches the new final line, and
the output winbar contains `FOLLOW`.

**Step 2: Run the focused test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_panel_spec.lua" "+qa!"
```

Expected: the test fails because the panel has neither `output_states` nor an
`output_rendered` branch.

**Step 3: Implement panel-local follow state and UI helpers**

Add panel-local state indexed by service key:

```lua
panel.output_states = {}

function Panel:_output_state(panel, service)
  panel.output_states[service.key] = panel.output_states[service.key]
    or { following = true, unseen_lines = 0, view = nil }
  return panel.output_states[service.key]
end
```

Add helpers to:

- Return `LOG [FOLLOW]` or `LOG [PAUSED - N new - G tail]`.
- Run in `panel.output_win` with `nvim_win_call` and move the cursor to the
  last retained line using `normal! G`.
- Detect a tail cursor by comparing `nvim_win_get_cursor(winid)[1]` with the
  displayed buffer's `nvim_buf_line_count`.
- Capture a paused view with `winsaveview()` before switching services and
  restore it with `winrestview()` when returning to that paused service.
- Set the output winbar without changing the current Neovim window.

In `_show_output`, initialize state for normal renderer output. A new service
or a service whose state is following goes to the tail; a paused service restores
its saved view. Skip follow behavior for `terminal_output`, which retains
terminal-native scrolling.

Create panel-owned `CursorMoved`, `WinScrolled`, and `CmdlineEnter` autocmds.
Each callback must verify that the panel and its output window are valid and
that the current output buffer is the selected normal renderer buffer.

- `CursorMoved` and `WinScrolled` update state from the tail-cursor check.
- `CmdlineEnter` pauses only when `args.match` is `/` or `?` and the output
  window is current.
- Reaching the final line enables following and clears `unseen_lines`.
- Leaving it disables following and snapshots the view.

Clean the panel-owned autocmd group when `Panel:close()` runs or when its list
window closes.

**Step 4: Handle output events without list re-rendering**

At the beginning of `Panel:_on_runtime_event`, branch on `output_rendered`:

```lua
if event.type == "output_rendered" then
  for _, panel in pairs(self.panels) do
    if panel_valid(panel) and panel.focused_key == service.key then
      self:_handle_output_rendered(panel, service, event.detail)
    end
  end
  return
end
```

`_handle_output_rendered` must verify that the output window still displays
`detail.bufnr`. If state is following, tail the window. If paused, add
`detail.appended` to `unseen_lines` and preserve the existing cursor/view.
Update only the output winbar. Do not call `render(panel)` or `_show_output()`
for this event.

For normal `starting` events, reset that service's state to following with zero
unread lines because `Runtime:start()` clears its normal renderer before a new
generation begins.

**Step 5: Run the focused test to verify it passes**

Run the Task 3 command again.

Expected: `services-panel-tests: ok`.

**Step 6: Commit the user-facing follow behavior**

```bash
git add nvim/lua/services/panel.lua nvim/tests/services_panel_spec.lua
git commit -m "feat(services): follow live logs without disrupting search"
```

### Task 4: Run Services regression checks and inspect the final diff

**Files:**
- Verify: `nvim/lua/services/output.lua`
- Verify: `nvim/lua/services/runtime.lua`
- Verify: `nvim/lua/services/panel.lua`
- Verify: `nvim/tests/services_output_spec.lua`
- Verify: `nvim/tests/services_runtime_spec.lua`
- Verify: `nvim/tests/services_panel_spec.lua`

**Step 1: Run focused Services tests**

Run each command independently:

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_output_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_runtime_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_panel_spec.lua" "+qa!"
```

Expected: each command prints its existing `services-*-tests: ok` marker.

**Step 2: Run adjacent shared-output coverage**

Run:

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/java_debug_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_zoom_spec.lua" "+qa!"
```

Expected: the DAP and resize paths continue to use the normal Services renderer
without follow logic affecting terminal-backed output.

**Step 3: Check formatting and scope**

Run:

```bash
stylua --check nvim/lua/services/output.lua nvim/lua/services/runtime.lua nvim/lua/services/panel.lua nvim/tests/services_output_spec.lua nvim/tests/services_runtime_spec.lua nvim/tests/services_panel_spec.lua
git diff --check
git status --short
```

Expected: no whitespace errors; only the six planned implementation and test
files are staged by the task commits. Do not stage existing unrelated Karabiner,
project-search, or key-map worktree changes.
