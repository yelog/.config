# Maven Reactor Lifecycle Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make lifecycle commands selected on Maven aggregator projects compile their full reactor.

**Architecture:** Add an idempotent local adapter for the upstream Projects view. It retains the upstream command builder, removes `-N` only when the selected project has children, and uses that command only in lifecycle execution.

**Tech Stack:** Neovim Lua, `oclay1st/maven.nvim`, headless Neovim specs.

---

### Task 1: Specify reactor command behavior

**Files:**
- Modify: `nvim/tests/maven_plugin_spec.lua`
- Create: `nvim/tests/maven_reactor_execution_spec.lua`

**Step 1: Write failing tests**

Assert a project with `modules = { child }` produces an argument list without
`-N`, retaining `--file=...` and `compile`. Assert a leaf retains the upstream
argument list unchanged. Stub the upstream Projects view, builder, console, and
configuration; invoke the installed lifecycle handler and assert the dispatched
arguments follow the same rule.

**Step 2: Run tests to verify failure**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_reactor_execution_spec.lua" "+qa!"
```

Expected: failure because `custom.maven_reactor_execution` does not exist.

### Task 2: Add the runtime lifecycle adapter

**Files:**
- Create: `nvim/lua/custom/maven_reactor_execution.lua`
- Test: `nvim/tests/maven_reactor_execution_spec.lua`

**Step 1: Implement a pure command helper**

Call `maven.utils.cmd_builder.build_mvn_cmd(pom_xml_path, { lifecycle_arg })`.
If and only if `project.modules` is a non-empty list, build a new argument list
excluding exact `-N`; otherwise return the upstream command object unchanged.

**Step 2: Implement idempotent installation**

Require `maven.ui.projects_view`, `maven.utils.console`, and `maven.config`.
Replace `_load_lifecycle_node` with the upstream callback and rendering flow,
using the pure helper to construct its command. Guard installation with a module
local boolean.

**Step 3: Run focused tests**

Run the Task 1 command. Expected: `maven-reactor-execution-spec-tests: ok`.

### Task 3: Wire and verify the panel

**Files:**
- Modify: `nvim/lua/plugins/panel/maven.lua`
- Modify: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Wire the adapter after the project-tree adapter**

Call `require("custom.maven_reactor_execution").install()` after Maven setup
and tree installation, before applying profiles.

**Step 2: Run focused regression tests**

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_reactor_execution_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_project_tree_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_plugin_spec.lua" "+qa!"
```

Expected: all three print their success markers.

### Task 4: Review and commit

**Files:**
- Review: `docs/plans/2026-07-21-maven-reactor-lifecycle-design.md`
- Review: `docs/plans/2026-07-21-maven-reactor-lifecycle.md`
- Review: implementation and test files above

**Step 1: Inspect the targeted diff**

Run `git diff --check` and `git diff --` for the six scoped files.

**Step 2: Commit the scoped change**

```bash
git add docs/plans/2026-07-21-maven-reactor-lifecycle-design.md docs/plans/2026-07-21-maven-reactor-lifecycle.md nvim/lua/custom/maven_reactor_execution.lua nvim/lua/plugins/panel/maven.lua nvim/tests/maven_reactor_execution_spec.lua nvim/tests/maven_plugin_spec.lua
git commit -m "fix(nvim): run Maven aggregator lifecycles recursively"
```
