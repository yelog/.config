# Maven Dependency Deep Search Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand every visible ancestor in a filtered Maven dependency tree.

**Architecture:** Use NUI Tree's normalized node `_id` for recursive child
lookups; preserve existing query, focus, and rendering behavior.

**Tech Stack:** Neovim Lua, `MunifTanjim/nui.nvim`, headless Neovim specs.

---

### Task 1: Reproduce a deep filtered path

**Files:**
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua`

**Step 1: Change the fixture to `root -> framework-core -> fastjson`.**

**Step 2: Assert searching `fastjson` renders that final node.**

### Task 2: Correct NUI child lookup

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua:172-179`

**Step 1: Query child nodes with `node._id`, not public `node.id`.**

**Step 2: Run:**

```bash
nvim --headless -u NONE "+luafile nvim/tests/maven_dependency_analyzer_spec.lua" "+qa!"
```

Expected: `maven-dependency-analyzer-tests: ok`.

### Task 3: Verify regressions

**Step 1: Run all Maven specs in isolated Neovim processes.**

**Step 2: Run `git diff --check`.**

**Step 3: Do not commit unless explicitly requested.**
