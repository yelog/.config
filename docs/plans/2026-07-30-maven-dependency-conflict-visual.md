# Maven Dependency Conflict Visual Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add theme-adaptive artifact hierarchy and unmissable Maven conflict
markers to the dependency analyzer.

**Architecture:** Keep conflict data in the existing dependency model. Add a
small analyzer-local highlight setup and a status-aware NUI line renderer.

**Tech Stack:** Neovim Lua, `MunifTanjim/nui.nvim`, headless Neovim specs.

---

### Task 1: Add failing conflict rendering coverage

**Files:**
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua`

**Step 1:** Add direct and transitive dependency fixtures with
`conflict_version`.

**Step 2:** Assert direct conflicts include `D`, `[! CONFLICT]`, the active
version, and the omitted version.

### Task 2: Add semantic visual roles

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua`

**Step 1:** Define default-linked Maven highlight groups for direct,
transitive, duplicate, conflict rail, badge, and conflict versions.

**Step 2:** Refactor node rendering so direct and conflict markers compose,
then render the version comparison beside the dependency metadata.

**Step 3:** Ensure Search remains the highest-priority artifact emphasis.

### Task 3: Verify regressions

**Files:**
- Test: `nvim/tests/maven_dependency_model_spec.lua`
- Test: `nvim/tests/maven_dependency_analyzer_spec.lua`
- Test: `nvim/tests/maven_profiles_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1:** Run each spec in an isolated Neovim process.

**Step 2:** Run `git diff --check`.

**Step 3:** Do not commit unless explicitly requested.
