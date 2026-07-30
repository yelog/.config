# Maven Dependency Remote Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an `R` shortcut that refreshes the Maven dependency graph with
the Maven `-U` remote-update option.

**Architecture:** Reuse upstream dependency loading. Temporarily wrap only the
dependency graph command builder to inject `-U`, then restore it synchronously
after loader invocation constructs the command.

**Tech Stack:** Neovim Lua, `oclay1st/maven.nvim`, headless Neovim specs.

---

### Task 1: Add failing remote-refresh coverage

**Files:**
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua`

**Step 1:** Stub `maven.utils.cmd_builder` and capture dependency graph command
arguments from the Maven source stub.

**Step 2:** Trigger `R`; assert exactly one `-U` is present and the original
builder is restored.

### Task 2: Add scoped `-U` refresh

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua`

**Step 1:** Add a helper that invokes a callback while a temporary dependency
graph builder injects `-U`.

**Step 2:** Extend `M.open(force, remote_update)` to use this helper only for
remote updates and to issue an accurate loading notification.

**Step 3:** Map `R` and label it in the control rail.

### Task 3: Verify regressions

**Files:**
- Test: `nvim/tests/maven_dependency_analyzer_spec.lua`
- Test: `nvim/tests/maven_dependency_model_spec.lua`
- Test: `nvim/tests/maven_profiles_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1:** Run each spec in an isolated Neovim process.

**Step 2:** Run `git diff --check`.

**Step 3:** Do not commit unless explicitly requested.
