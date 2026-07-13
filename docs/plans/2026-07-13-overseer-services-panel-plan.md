# Overseer Spring Boot Services Panel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade the Overseer Spring Boot task list into an IDEA-like Services panel with persistent profiles, clear states, failure-first ordering, detected ports, and browser actions.

**Architecture:** Add a small project-state module for profile persistence and a dedicated Overseer component for launch-time profile injection and Spring Boot output parsing. Keep Overseer as the task/output engine while the existing panel configuration owns visual rendering, actions, keymaps, and discovery.

**Tech Stack:** Lua, Neovim 0.11 APIs, overseer.nvim components and task-list APIs, JSON state storage

---

### Task 1: Project profile state

**Files:**
- Create: `nvim/lua/overseer/service_state.lua`
- Create: `nvim/tests/overseer_services_spec.lua`

**Step 1: Add failing state assertions**

Cover missing state, invalid JSON fallback, per-project profile isolation, state round-trip, and Maven profile parsing with whitespace/comments.

**Step 2: Run the headless test**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/overseer_services_spec.lua" "+qa!"
```

Expected: failure because `overseer.service_state` does not exist.

**Step 3: Implement the state module**

Expose:

```lua
setup(opts)
get_profile(project_root)
set_profile(project_root, profile)
parse_maven_profiles(project_root)
```

Use `stdpath("state")/overseer/spring-services.json` by default, cache decoded state in memory, create the parent directory before writes, and return empty results on read/parse failure.

**Step 4: Run the test**

Expected: state and profile parsing assertions pass.

### Task 2: Spring Boot task component

**Files:**
- Create: `nvim/lua/overseer/component/service/springboot.lua`
- Modify: `nvim/tests/overseer_services_spec.lua`

**Step 1: Add failing component assertions**

Use a fake task to verify:

- stale Maven `-P` arguments are replaced on every `on_pre_start`;
- startup clears stale runtime metadata;
- Tomcat, Netty, Jetty, and Undertow lines produce protocol/port/context metadata;
- the final Spring `Started` line marks the service ready;
- exit clears readiness.

**Step 2: Implement the component**

The component reads profile state from `task.metadata.project_root`, mutates `task.cmd` before launch, parses `on_output_lines`, writes `task.metadata.url`, and touches the Overseer task list when visible metadata changes.

**Step 3: Run the test**

Expected: all component lifecycle assertions pass.

### Task 3: Spring Boot template identity and metadata

**Files:**
- Modify: `nvim/lua/overseer/template/springboot.lua`
- Modify: `nvim/tests/overseer_services_spec.lua`

**Step 1: Replace generation-time profile injection**

Remove direct reads of `vim.g.overseer_spring_profile`. Add `service.springboot` after `on_exit_set_status` and pass stable metadata:

```lua
springboot = true
project_root = root
module = relative_module
class = ep.fqn
```

**Step 2: Make task names unique**

Display `module:Application` for multi-module entries and `Application` for a single module. Preserve class metadata as the stable identity.

**Step 3: Improve discovery correctness**

Fix the directory guard, use `vim.uv`, accept Kotlin package declarations without semicolons, and parse profile blocks through `overseer.service_state`.

**Step 4: Run tests and a template discovery probe**

Expected: same-named applications in different modules produce distinct template names and metadata.

### Task 4: Services panel interaction and visuals

**Files:**
- Modify: `nvim/lua/plugins/panel/overseer.lua`

**Step 1: Add project context and winbar**

Capture the active project root before opening Overseer. Render one project-level profile label in the `OverseerList` winbar and refresh it on profile changes and list updates.

**Step 2: Replace task-row rendering**

Render ready, starting, stopped, failed, canceled, and success states with distinct icon/highlight pairs. Show `:port` only for ready services.

**Step 3: Replace sorting**

Sort failures first, then ready/running, starting, pending, canceled, and success. Use module/name as a stable tie-breaker.

**Step 4: Implement direct profile selection**

Map `p` directly to `vim.ui.select`, move preview to `gp`, persist the selected profile, update the winbar, and call `task:restart(true)` only for running Spring Boot tasks.

**Step 5: Implement URL opening**

Add an `open_service_url` action and map `u` to it. Call `vim.ui.open(task.metadata.url)` when ready; otherwise notify the user.

### Task 5: Safe task discovery

**Files:**
- Modify: `nvim/lua/plugins/panel/overseer.lua`

**Step 1: Prevent discovery from starting processes**

Build only templates returned by the local `springboot` and `service` providers with:

```lua
template.build_task(template_definition, {
  params = {},
  search = { dir = project_root },
  disallow_prompt = true,
})
```

Do not call the global template listing API, because unrelated providers may launch external discovery commands. Building a task directly registers it as `PENDING` without starting it.

**Step 2: Scope discovery and identity**

Only register service/Spring Boot templates and deduplicate with Spring class/project metadata instead of name alone.

**Step 3: Verify panel commands**

Open and toggle the panel in a fixture project and confirm registration leaves all new tasks in `PENDING`.

### Task 6: Final verification

**Files:**
- Test: `nvim/tests/overseer_services_spec.lua`

**Step 1: Run the headless behavior tests**

Expected: all assertions pass.

**Step 2: Load the complete Neovim configuration headlessly**

Run:

```bash
nvim --headless "+lua require('lazy').load({ plugins = { 'overseer.nvim' } })" "+qa!"
```

Expected: no Lua errors.

**Step 3: Run formatting and diff checks**

Run `stylua --check` for changed Lua files and `git diff --check`.

**Step 4: Manually verify UX**

Confirm the profile winbar, one-step `p` selection, restored profile after restart, failure-first ordering, distinct statuses, detected port, and `u` browser action.
