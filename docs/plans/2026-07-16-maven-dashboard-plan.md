# Maven Dashboard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a lazy-loaded Maven project dashboard and a separate, project-scoped Maven Profile picker to the Neovim configuration.

**Architecture:** Configure `oclay1st/maven.nvim` as an independent right-side panel. A local `custom.maven_profiles` module owns Maven Profile discovery, persistence, picker behavior, and default-argument injection, while leaving `services.state` and the Spring Boot Services panel untouched.

**Tech Stack:** Neovim 0.11, Lua, lazy.nvim, `oclay1st/maven.nvim`, fzf-lua, `vim.system()`, headless Neovim tests.

---

### Task 1: Add a Maven Profile Helper Regression Test

**Files:**
- Create: `nvim/tests/maven_profiles_spec.lua`
- Reference: `nvim/tests/services_state_catalog_spec.lua:1-61`
- Reference: `nvim/lua/services/state.lua:30-118`

**Step 1: Write the failing test**

Create a headless spec that adds `nvim/lua` to `package.path`, uses a temporary state file, and verifies these contracts:

- `parse_profiles` extracts unique, sorted IDs from representative `help:all-profiles` output.
- selected Maven Profiles persist by normalized project root and are separate from any Services state.
- `apply_profiles` adds one tagged and enabled `-P=<comma-separated-list>` default argument, preserves unrelated default arguments, and removes only its own tagged argument on clear.
- a missing `pom.xml` makes profile discovery return an error without mutating stored selection.

Use a fake Maven config table rather than loading the external plugin:

```lua
local config = {
  options = {
    default_arguments_view = {
      arguments = { { arg = "-DskipTests", enabled = true } },
    },
  },
}

profiles.apply_profiles({ "dev", "uat" }, config)
assert_equal("-P", config.options.default_arguments_view.arguments[2].arg)
assert_equal("dev,uat", config.options.default_arguments_view.arguments[2].value)
```

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_profiles_spec.lua" "+qa!"
```

Expected: failure because `custom.maven_profiles` does not exist.

### Task 2: Implement the Isolated Maven Profile Helper

**Files:**
- Create: `nvim/lua/custom/maven_profiles.lua`
- Test: `nvim/tests/maven_profiles_spec.lua`

**Step 1: Add the state and pure-data API**

Implement these testable functions:

- `setup(opts)` sets the state path and optional command runner.
- `parse_profiles(output)` parses `Profile Id: <id> (...)` lines, trims values, removes duplicates, and sorts IDs.
- `get_profiles(root)` and `set_profiles(root, profiles)` read and atomically replace `{ projects = { [root] = { profiles = {} } } }` JSON state.
- `apply_profiles(profiles, config)` manages only default-argument entries marked with `_maven_dashboard_profile = true`.

Use `vim.fs.normalize`, `vim.json.encode`, `vim.fn.writefile`, a temporary sibling file, and `vim.uv.fs_rename`. Never read or write `services.state`.

**Step 2: Add project discovery and asynchronous Maven query**

Find the Maven root using `mvnw` or `pom.xml`. Query profiles using an argv array, not a shell string:

```lua
{
  executable,
  "--batch-mode",
  "--non-recursive",
  "--file",
  pom_path,
  "help:all-profiles",
}
```

Use `vim.system(..., { cwd = root, text = true }, callback)` and return stdout/stderr to the UI callback. Read `maven.config.options.mvn_executable` after ensuring the Lazy plugin is loaded, falling back to `mvn` only if the module is unavailable.

**Step 3: Add picker, commands, and current-directory synchronization**

Implement a fzf-lua multi-select picker with a clear-selection row. Persist the selected values and call `apply_profiles` after a selection. Expose:

```lua
:MavenProfiles
:MavenProfilesClear
```

`setup()` must register these commands and apply the stored profile state for the initial working directory and on `DirChanged`.

**Step 4: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_profiles_spec.lua" "+qa!"
```

Expected: `maven-profile-tests: ok`.

### Task 3: Add a Maven Plugin Specification Regression Test

**Files:**
- Create: `nvim/tests/maven_plugin_spec.lua`
- Reference: `nvim/tests/neo_tree_spec.lua`

**Step 1: Write the failing test**

Stub `maven.setup` and `custom.maven_profiles.apply_current`, load `nvim/lua/plugins/panel/maven.lua`, invoke its `config`, and assert:

- the plugin is `oclay1st/maven.nvim`;
- it uses `MunifTanjim/nui.nvim` rather than introducing a duplicate UI dependency;
- Maven commands are lazy triggers;
- `mvn_executable` is `mvn`;
- the project view is right-aligned and uses the agreed width;
- setup applies the persisted current-project Profile after Maven setup.

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_plugin_spec.lua" "+qa!"
```

Expected: failure because the plugin specification is absent.

### Task 4: Add the Lazy Maven Dashboard Specification

**Files:**
- Create: `nvim/lua/plugins/panel/maven.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Define the lazy plugin**

Configure `oclay1st/maven.nvim` with:

```lua
cmd = { "Maven", "MavenExec", "MavenInit", "MavenFavorites" }
dependencies = { "MunifTanjim/nui.nvim" }
opts = {
  mvn_executable = "mvn",
  project_scanner_depth = 5,
  projects_view = { position = "right", size = 55 },
}
```

In `config`, call `require("maven").setup(opts)` first, then `require("custom.maven_profiles").apply_current()`.

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_plugin_spec.lua" "+qa!"
```

Expected: `maven-plugin-spec-tests: ok`.

### Task 5: Register the Helper and User Keymaps

**Files:**
- Modify: `nvim/init.lua:55-61`
- Modify: `nvim/lua/key-map.lua:5-19`
- Modify: `nvim/lua/key-map.lua:456-478`
- Modify: `nvim/lua/plugins/tools.lua:32-38`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Initialize the independent profile helper**

Add `require("custom.maven_profiles").setup()` after Lazy setup. The module must not require `maven.nvim` until a profile action actually needs it.

**Step 2: Add the Operations group and Maven mappings**

Keep existing Services mappings unchanged. Register `<leader>o` as the Operations group and add:

```lua
map("n", "<leader>om", function() require("custom.maven_profiles").open_dashboard() end,
  { desc = "Toggle Maven panel" })
map("n", "<leader>op", "<cmd>MavenProfiles<cr>", { desc = "Select Maven profiles" })
map("n", "<leader>ox", function() require("custom.maven_profiles").open_execution() end,
  { desc = "Execute Maven command" })
map("n", "<leader>of", function() require("custom.maven_profiles").open_favorites() end,
  { desc = "Maven favorite commands" })
```

Add `vim.g.rooter_buftypes = { "" }` in `nvim/lua/plugins/tools.lua`. Rooter must ignore NUI `nofile` buffers so Maven panels do not reset the project working directory after the mappings resolve it.

**Step 3: Extend the test**

Assert that the normal-mode mappings resolve to their commands and that `:MavenProfiles` and `:MavenProfilesClear` exist after a full configuration load.

**Step 4: Run focused tests**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_profiles_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_plugin_spec.lua" "+qa!"
```

Expected: both tests pass.

### Task 6: Document the Workflow and Install the Plugin

**Files:**
- Modify: `nvim/README.md:60-72`
- Modify: `nvim/lazy-lock.json`

**Step 1: Document the Maven dashboard**

Add a concise Maven section covering startup from a Maven project root, the four mappings, profile persistence location, and the upstream limitation that `:MavenExec` and dependency metadata do not inherit selected Profiles.

**Step 2: Synchronize Lazy**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+Lazy! sync" "+qa!"
```

Expected: `oclay1st/maven.nvim` is installed and `nvim/lazy-lock.json` gains the `maven.nvim` entry.

### Task 7: Run Final Validation

**Files:**
- Verify: `docs/plans/2026-07-16-maven-dashboard-design.md`
- Verify: `docs/plans/2026-07-16-maven-dashboard-plan.md`
- Verify: `nvim/lua/custom/maven_profiles.lua`
- Verify: `nvim/lua/plugins/panel/maven.lua`
- Verify: `nvim/init.lua`
- Verify: `nvim/lua/key-map.lua`
- Verify: `nvim/README.md`
- Verify: `nvim/tests/maven_profiles_spec.lua`
- Verify: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Run all focused Maven tests**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_profiles_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_plugin_spec.lua" "+qa!"
```

Expected: both report success.

**Step 2: Load the full configuration and validate public entry points**

Run:

```bash
nvim --headless -u /Users/yelog/.config/nvim/init.lua "+lua assert(vim.fn.exists(':Maven') == 2); assert(vim.fn.exists(':MavenProfiles') == 2); assert(vim.fn.exists(':MavenProfilesClear') == 2); assert(vim.fn.maparg(' om', 'n'):find('Maven', 1, true))" "+qa!"
```

Expected: exit code 0.

**Step 3: Check formatting and scoped diff**

Run:

```bash
stylua --check nvim/lua/custom/maven_profiles.lua nvim/lua/plugins/panel/maven.lua nvim/lua/key-map.lua nvim/init.lua nvim/tests/maven_profiles_spec.lua nvim/tests/maven_plugin_spec.lua
```

Expected: no formatting or whitespace errors. Do not commit unless explicitly requested.
