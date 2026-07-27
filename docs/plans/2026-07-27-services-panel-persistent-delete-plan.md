# Services Panel Persistent Delete Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `dd` permanently remove a selected service from the current project's Services panel.

**Architecture:** Keep persisted-selection mutation in `services.panel`, which owns the user action and project root. Preserve `services.runtime` as a volatile resource manager. Persist the filtered key list before disposal so a failed write leaves both state and runtime unchanged.

**Tech Stack:** Lua, Neovim APIs, JSON-backed service state, headless Neovim tests.

---

### Task 1: Cover Persistent Disposal

**Files:**
- Modify: `nvim/tests/services_panel_spec.lua:76-92,234-252`
- Modify: `nvim/lua/services/panel.lua:411-428,520-523`

**Step 1: Write failing tests**

Add a test helper state that records writes. Assert that permanent disposal:

- removes the service key from `selected_services`;
- removes the runtime service after persistence succeeds;
- does not dispose the runtime service when persistence fails.

**Step 2: Run the test and verify it fails**

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_panel_spec.lua" "+qa!"
```

Expected: FAIL because `dd` disposal does not mutate persisted selections.

**Step 3: Implement the minimal panel action**

In `Panel:dispose_service`, filter `state.get_selected_services(service.metadata.project_root)` to exclude `service.key`. Call `state.set_selected_services` with the filtered list. On failure, notify and return `false`; otherwise retain the existing stopped/running disposal behavior.

**Step 4: Run the test and verify it passes**

Run the command above. Expected: `services-panel-tests: ok`.

### Task 2: Verify Formatting And Related State Behavior

**Files:**
- Verify: `nvim/tests/services_panel_spec.lua`
- Verify: `nvim/tests/services_state_catalog_spec.lua`
- Verify: `nvim/lua/services/panel.lua`

**Step 1: Run affected specifications**

```bash
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_panel_spec.lua" "+qa!"
nvim --headless -u NONE "+set rtp+=$PWD/nvim" "+luafile $PWD/nvim/tests/services_state_catalog_spec.lua" "+qa!"
```

Expected: both specifications report `ok`.

**Step 2: Check formatting and whitespace**

```bash
stylua --check nvim/lua/services/panel.lua nvim/tests/services_panel_spec.lua
```

Expected: both commands exit successfully.
