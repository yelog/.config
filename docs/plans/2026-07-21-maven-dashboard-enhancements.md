# Maven Dashboard Enhancements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Persist Maven dashboard settings per project and unify its Profile behavior with Spring service launches.

**Architecture:** Extend the existing `custom.maven_profiles` state adapter with validated project arguments and command presets, then project those values into upstream `maven.nvim` configuration. Delegate Maven profile lookup from the service state layer so Maven keeps multi-profile execution while services use the first selected profile.

**Tech Stack:** Neovim Lua, `oclay1st/maven.nvim`, `fzf-lua`, headless Neovim specs.

---

### Task 1: Specify project Maven settings

**Files:**
- Modify: `nvim/tests/maven_profiles_spec.lua`
- Modify: `nvim/lua/custom/maven_profiles.lua`

**Step 1: Write failing tests**

Assert that arguments and commands are normalized, persisted per root, restored
to Maven configuration, and that `get_primary_profile` returns the first sorted
selected profile.

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile nvim/tests/maven_profiles_spec.lua" "+qa!"
```

Expected: failure because the project-setting APIs do not exist.

**Step 3: Implement project settings**

Add validated `get_*`, `set_*`, `get_primary_profile`, and `apply_current`
support in `custom.maven_profiles`. Preserve only user arguments in state and
append the generated Profile argument afterwards.

**Step 4: Re-run the focused test**

Run the Task 1 command. Expected: `maven-profile-tests: ok`.

### Task 2: Reuse Maven Profile state for service launches

**Files:**
- Modify: `nvim/lua/services/state.lua`
- Modify: `nvim/tests/services_state_catalog_spec.lua`

**Step 1: Write a failing test**

Stub `custom.maven_profiles` and assert Maven project profile lookup returns
its primary Profile without changing other state operations.

**Step 2: Run the focused test**

Run:

```bash
nvim --headless -u NONE "+luafile nvim/tests/services_state_catalog_spec.lua" "+qa!"
```

Expected: failure because `services.state` still only parses local POM XML.

**Step 3: Implement delegation**

Use `custom.maven_profiles.get_primary_profile` when available; retain the
existing state fallback for non-Maven contexts.

**Step 4: Re-run the focused test**

Run the Task 2 command. Expected: the state catalog spec success marker.

### Task 3: Document Maven usage

**Files:**
- Create: `nvim/MAVEN.md`

**Step 1: Write the usage guide**

Document prerequisites, commands, keymaps, project-tree interactions,
Profile behavior, presets, default arguments, dependency analysis, output, and
known upstream constraints.

**Step 2: Verify documentation references**

Compare every documented command and mapping with `key-map.lua`,
`maven_profiles.lua`, and upstream `maven.nvim` configuration.

### Task 4: Run regression suite

**Files:**
- Test: `nvim/tests/maven_profiles_spec.lua`
- Test: `nvim/tests/maven_project_tree_spec.lua`
- Test: `nvim/tests/maven_reactor_execution_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`
- Test: `nvim/tests/services_state_catalog_spec.lua`

**Step 1: Run all focused specs**

Run each headless Neovim spec independently.

**Step 2: Inspect the scoped diff**

Run:

```bash
git diff --check
```

Expected: no whitespace errors and only Maven dashboard implementation,
tests, plans, and documentation changes.
