# Maven Dependency Refresh Context Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make in-panel Maven dependency refresh shortcuts reuse the panel's
original module POM.

**Architecture:** Add an optional POM path argument to `M.open()`. Pass the
analyzer's stored path from its local and remote refresh mappings while keeping
external command discovery unchanged.

**Tech Stack:** Neovim Lua, `MunifTanjim/nui.nvim`, headless Neovim specs.

---

### Task 1: Add a failing in-panel refresh test

**Files:**
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua`

**Step 1:** Make the nearest-POM stub return the module POM only for the first
open and nil afterward.

**Step 2:** Trigger `R` in the NUI popup and assert the Maven source receives
the original POM path.

### Task 2: Preserve panel POM context

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua`

**Step 1:** Add an optional `pom_path` argument to `M.open()`.

**Step 2:** Pass `self.pom_path` from `r` and `R` mappings.

**Step 3:** Run the analyzer spec and verify it passes.

### Task 3: Verify regressions

**Files:**
- Test: `nvim/tests/maven_dependency_analyzer_spec.lua`
- Test: `nvim/tests/maven_dependency_model_spec.lua`
- Test: `nvim/tests/maven_profiles_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1:** Run each spec in an isolated Neovim process.

**Step 2:** Run `git diff --check`.

**Step 3:** Do not commit unless explicitly requested.
