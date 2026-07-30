# Maven Dependency Search Interaction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore focus to the Maven dependency tree and expand visible result
paths after accepting a search query.

**Architecture:** Keep query state in `Analyzer`. Add a render flag that expands
only nodes built for a non-empty search and restore the popup window from the
input callback.

**Tech Stack:** Neovim Lua, `MunifTanjim/nui.nvim`, headless Neovim specs.

---

### Task 1: Add failing interaction coverage

**Files:**
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua`

**Step 1: Stub `vim.ui.input` with an accepted query.**

**Step 2: Assert the popup is focused and matching-tree parents are expanded.**

**Step 3: Run:**

```bash
nvim --headless -u NONE "+luafile nvim/tests/maven_dependency_analyzer_spec.lua" "+qa!"
```

Expected: FAIL before implementation.

### Task 2: Restore focus and expand results

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua:172-220`

**Step 1: Add a recursive visible-tree expansion helper.**

**Step 2: On an accepted non-empty query, render with expansion and restore
`popup.winid` if valid.**

**Step 3: Run the analyzer spec again.**

Expected: `maven-dependency-analyzer-tests: ok`.

### Task 3: Run focused regressions

**Files:**
- Test: `nvim/tests/maven_dependency_model_spec.lua`
- Test: `nvim/tests/maven_dependency_analyzer_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Run each headless spec in a separate Neovim process.**

**Step 2: Run `git diff --check`.**

**Step 3: Do not commit unless explicitly requested.**
