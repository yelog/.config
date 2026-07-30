# Maven Dependency Workbench Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a visually structured, keyboard-first Maven dependency workbench
with statistics, direct-dependency context, metadata controls, sorting, and
POM navigation.

**Architecture:** Add pure summary and ordering helpers to the dependency
model. Keep NUI layout, presentation state, and POM navigation in the analyzer.

**Tech Stack:** Neovim Lua, `MunifTanjim/nui.nvim`, headless Neovim specs.

---

### Task 1: Add model summary and ordering

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_model.lua`
- Modify: `nvim/tests/maven_dependency_model_spec.lua`

**Step 1:** Add failing assertions for direct, resolved, conflict, aggregate
size summary values and stable descending size ordering.

**Step 2:** Implement `summary(graph)` and `ordered_ids(graph, ids, options)`.

**Step 3:** Run the model spec and confirm it passes.

### Task 2: Render the workbench hierarchy

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua`
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua`

**Step 1:** Add analyzer state for group visibility and size sorting.

**Step 2:** Render identity, summary, and compact command rail lines; render
artifact-first rows with direct/duplicate/conflict state markers and semantic
highlights.

**Step 3:** Apply model ordering in tree and list construction without losing
search path preservation.

**Step 4:** Add `g` and `s` mappings and assert their affordances render.

### Task 3: Add direct POM navigation

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua`
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua`

**Step 1:** Add an `o` mapping that only navigates roots.

**Step 2:** Switch to the original editor window, edit the active POM, and
search for the direct dependency's artifactId.

**Step 3:** For a transitive dependency, notify users to inspect paths instead.

### Task 4: Verify regressions

**Files:**
- Test: `nvim/tests/maven_dependency_model_spec.lua`
- Test: `nvim/tests/maven_dependency_analyzer_spec.lua`
- Test: `nvim/tests/maven_profiles_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1:** Run each spec in an isolated Neovim process.

**Step 2:** Run `git diff --check`.

**Step 3:** Do not commit unless explicitly requested.
