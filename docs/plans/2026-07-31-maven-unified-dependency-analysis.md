# Maven Unified Dependency Analysis Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make every Maven dependency-analysis entry open the local dependency workbench for its intended module.

**Architecture:** Preserve `maven.nvim` as the Maven project and dependency-loading provider. Extend the existing local project-tree adapter to replace only the upstream panel's buffer-local `a` mapping, passing the selected project's exact POM path to the existing analyzer.

**Tech Stack:** Neovim Lua, `oclay1st/maven.nvim`, `MunifTanjim/nui.nvim`, headless Neovim specs.

---

### Task 1: Cover the panel-to-analyzer delegation

**Files:**
- Modify: `nvim/tests/maven_project_tree_spec.lua`

**Step 1: Write the failing test**

Stub `maven.ui.projects_view` with an `_setup_win_maps` method that records its
`a` mapping. Stub `custom.maven_dependency_analyzer.open`. After
`project_tree.install()`, invoke the installed `a` callback with a view whose
selected node belongs to a module project. Assert the analyzer receives
`false, false, "/workspace/module/pom.xml"`.

**Step 2: Run test to verify it fails**

Run: `nvim --headless -u NONE "+luafile nvim/tests/maven_project_tree_spec.lua" "+qa!"`

Expected: FAIL because the adapter does not replace the upstream `a` mapping.

**Step 3: Add empty-selection coverage**

Invoke the installed mapping with no selected node. Assert the analyzer is not
called and a warning notification is issued.

### Task 2: Replace the upstream dependency-view keymap

**Files:**
- Modify: `nvim/lua/custom/maven_project_tree.lua`

**Step 1: Implement the minimal adapter**

Inside `install()`, require `maven.ui.projects_view`, save its original
`_setup_win_maps`, then replace it with a wrapper. The wrapper must call the
original method first and then install a buffer-local normal-mode `a` mapping
through `self._win:map`.

**Step 2: Delegate using the selected module POM**

The mapping must use `self._tree:get_node()` and `self:_lookup_project` to
resolve the owning project. On no node, notify `Not project selected`. Otherwise
call `require("custom.maven_dependency_analyzer").open(false, false,
project.pom_xml_path)`.

**Step 3: Preserve installation idempotence**

Keep the existing `installed` guard so repeated plugin setup cannot wrap either
upstream function more than once.

**Step 4: Run the focused test**

Run: `nvim --headless -u NONE "+luafile nvim/tests/maven_project_tree_spec.lua" "+qa!"`

Expected: `maven-project-tree-spec-tests: ok`.

### Task 3: Run regression checks

**Files:**
- Test: `nvim/tests/maven_project_tree_spec.lua`
- Test: `nvim/tests/maven_dependency_model_spec.lua`
- Test: `nvim/tests/maven_dependency_analyzer_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Run focused Maven specs**

Run: `for spec in nvim/tests/maven_project_tree_spec.lua nvim/tests/maven_dependency_model_spec.lua nvim/tests/maven_dependency_analyzer_spec.lua nvim/tests/maven_plugin_spec.lua; do nvim --headless -u NONE "+luafile $spec" "+qa!" || exit 1; done`

Expected: every spec prints its success marker.

**Step 2: Check patch whitespace**

Run: `git diff --check`

Expected: no output and exit code 0.

**Step 3: Commit**

Do not commit unless explicitly requested.
