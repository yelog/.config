# Overseer Service Selection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a project-scoped, initially empty Services panel with category-based multi-selection, persistent launch entries, type icons, compact rows, and bounded FIFO output.

**Architecture:** Extend the existing project state with selected stable service keys and add a small service catalog that normalizes providers, service types, and filtering. Keep Overseer responsible for task execution and output while the panel coordinates discovery, fzf-lua selection, task reconciliation, and rendering.

**Tech Stack:** Lua, Neovim 0.11 APIs, overseer.nvim at locked commit `a93d9f6`, fzf-lua, Nerd Font glyphs, JSON state storage

---

### Task 1: Persist Project Service Selections

**Files:**
- Modify: `nvim/tests/overseer_services_spec.lua`
- Modify: `nvim/lua/overseer/service_state.lua`

**Step 1: Add failing state assertions**

Add assertions that:

- `get_selected_services(root)` returns `{}` for missing and old profile-only state;
- `set_selected_services(root, keys)` normalizes duplicates and sorting;
- empty selections persist as an empty list rather than deleting the project profile;
- updating selections preserves `profile` and updates from other projects;
- invalid non-string entries are ignored on read.

**Step 2: Run the headless test and verify failure**

Run:

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/overseer_services_spec.lua" "+qa!"
```

Expected: FAIL because the selection state functions do not exist.

**Step 3: Implement selection persistence**

Add:

```lua
get_selected_services(project_root) -> string[]
set_selected_services(project_root, keys) -> boolean
```

Reuse the existing lock and atomic save path. Merge fields into the existing project object instead of replacing it, so profile and selection writes preserve one another.

**Step 4: Run the headless test**

Expected: all project state assertions pass.

### Task 2: Add the Service Catalog

**Files:**
- Create: `nvim/lua/overseer/service_catalog.lua`
- Modify: `nvim/tests/overseer_services_spec.lua`

**Step 1: Add failing catalog assertions**

Cover:

- known definitions for Spring Boot, npm, and custom service entries;
- a generic icon and label fallback for unknown types;
- stable keys from task/template metadata;
- normalization of provider output into `{ module, type, key, template }` entries;
- filtering entries by selected-key set;
- category replacement that preserves keys from other categories and stale unknown keys.

**Step 2: Run the test and verify failure**

Expected: FAIL because `overseer.service_catalog` does not exist.

**Step 3: Implement the catalog**

Keep the public API small:

```lua
get_type(service_type)
key_from_metadata(metadata, name)
discover(search_dir)
filter_selected(entries, selected_keys)
replace_category(selected_keys, entries, service_type, replacement_keys)
```

`discover` calls only the local `springboot`, `npm`, and `service` generators and never builds or starts tasks. Type definitions contain `label`, `icon`, and `hl`.

**Step 4: Run the headless test**

Expected: catalog assertions pass without loading the full plugin configuration.

### Task 3: Normalize Template Metadata and Bound Output

**Files:**
- Modify: `nvim/lua/overseer/template/springboot.lua`
- Modify: `nvim/lua/overseer/template/npm.lua`
- Modify: `nvim/lua/overseer/template/service.lua`
- Modify: `nvim/lua/overseer/component/service/lifecycle.lua`
- Modify: `nvim/tests/overseer_services_spec.lua`

**Step 1: Add failing metadata and lifecycle assertions**

Verify every builder emits one of:

```lua
metadata.service_type = "springboot"
metadata.service_type = "npm"
metadata.service_type = "service"
```

Construct `service.lifecycle`, provide a fake terminal buffer through `task:get_bufnr()`, invoke `on_start`, and assert `vim.bo[bufnr].scrollback == 10000`.

**Step 2: Run the test and verify failure**

Expected: FAIL because service type metadata and the output limit are absent.

**Step 3: Add service type metadata**

Add the single normalized metadata field to all three templates. Preserve current compatibility flags such as `springboot`, `npm`, and `service` because existing debug and URL actions use them.

**Step 4: Add lifecycle output limit**

Add an editable numeric `output_limit` parameter with default `10000`. In `on_start`, set terminal `scrollback` when the task buffer exists and is valid. Do not manually delete lines; Neovim terminal scrollback already performs FIFO eviction.

**Step 5: Run the headless test**

Expected: metadata and output-limit assertions pass.

### Task 4: Reconcile the Panel with Persisted Selection

**Files:**
- Modify: `nvim/lua/plugins/panel/overseer.lua`
- Modify: `nvim/tests/overseer_services_spec.lua`

**Step 1: Extract testable reconciliation helpers where needed**

Use `overseer.service_catalog` for discovery, type lookup, and keys. Keep UI callbacks local to the panel, but avoid duplicating key-generation rules.

**Step 2: Change panel opening to build selected entries only**

Replace unconditional `ensure_services` registration with:

1. discover all catalog entries;
2. load `selected_services` for the tab project root;
3. filter entries by selected key;
4. build only missing selected tasks.

If the saved selection is empty, open Overseer immediately with no tasks.

**Step 3: Implement `a` category and entry selection**

Use `vim.ui.select` for category selection with selected/available counts. Use:

```lua
require("fzf-lua").fzf_exec(items, {
  prompt = "Services> ",
  fzf_opts = { ["--multi"] = true },
  actions = {
    enter = function(selected)
      -- map display rows back to stable keys and apply category replacement
    end,
  },
})
```

Include a dedicated clear-category row so an entire category can be removed without requiring an fzf selection. Persist before mutating tasks.

**Step 4: Reconcile tasks after selection**

- Build newly selected templates.
- Dispose deselected tasks unless they are running or debugging.
- Keep deselected running/debugging tasks and issue one concise warning.
- Refresh the winbar and task list after reconciliation.

**Step 5: Add type icons and compact row spacing**

Render:

```text
 <status> <type> <name>  <detail>
```

Use one space after each icon. Resolve icons through catalog metadata with the generic fallback.

**Step 6: Update winbar and keymap**

- Add panel-local `a` as `Manage services`.
- Empty state: `SERVICES  0 selected  [a add]`.
- Populated state: type summary, selected count, and `[a manage]`.
- Preserve the Spring profile controls when Spring entries are present or selected.

**Step 7: Run behavior tests and load the configuration**

Run the headless service test, then:

```bash
nvim --headless "+lua require('lazy').load({ plugins = { 'overseer.nvim', 'fzf-lua' } })" "+qa!"
```

Expected: no Lua errors.

### Task 5: Final Verification

**Files:**
- Test: `nvim/tests/overseer_services_spec.lua`
- Review: all files changed above

**Step 1: Run the service behavior test**

```bash
nvim --headless -u NONE "+set rtp+=/Users/yelog/.config/nvim" "+luafile /Users/yelog/.config/nvim/tests/overseer_services_spec.lua" "+qa!"
```

Expected: `overseer-services-tests: ok`.

**Step 2: Run Lua formatting checks**

```bash
stylua --check nvim/lua/overseer/service_state.lua nvim/lua/overseer/service_catalog.lua nvim/lua/overseer/template/springboot.lua nvim/lua/overseer/template/npm.lua nvim/lua/overseer/template/service.lua nvim/lua/overseer/component/service/lifecycle.lua nvim/lua/plugins/panel/overseer.lua nvim/tests/overseer_services_spec.lua
```

Expected: exit code 0.

**Step 3: Run whitespace validation**

```bash
git diff --check
```

Expected: no output.

**Step 4: Manually verify the interaction**

Verify in a project containing Spring Boot and npm entries:

- first open shows an empty list and `[a add]`;
- `a` selects a category and multiple entries;
- reopening Neovim restores exactly those entries;
- row glyphs occupy one cell and names align compactly;
- removing a stopped entry disposes it;
- removing a running entry keeps it alive and warns;
- Spring profile switching, URL opening, debug, and start/stop-all continue to work;
- a noisy process never exceeds approximately 10,000 terminal lines.

No git commit is created unless the user explicitly requests one.
