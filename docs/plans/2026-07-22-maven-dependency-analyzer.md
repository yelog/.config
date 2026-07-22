# Maven Dependency Analyzer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a standalone, keyboard-first Maven dependency analyzer for the current POM.

**Architecture:** Keep graph selection logic in a pure local model and render it in a NUI popup. Reuse `maven.nvim` sources for Maven resolution, dependency caching, and console reporting rather than copying or patching upstream dependency loading.

**Tech Stack:** Neovim Lua, `MunifTanjim/nui.nvim`, `oclay1st/maven.nvim`, headless Neovim specs.

---

### Task 1: Build the dependency graph model

**Files:**
- Create: `nvim/lua/custom/maven_dependency_model.lua`
- Create: `nvim/tests/maven_dependency_model_spec.lua`

**Step 1: Write failing model specs**

Create occurrence fixtures with nested, duplicate, conflict, and test-scope
dependencies. Assert indexing, ancestor-preserving tree visibility,
deduplicated lists, conflict selection, scope hiding, and coordinate paths.

**Step 2: Run the spec to verify failure**

Run:

```bash
nvim --headless -u NONE "+luafile nvim/tests/maven_dependency_model_spec.lua" "+qa!"
```

Expected: failure because `custom.maven_dependency_model` does not exist.

**Step 3: Implement the pure model**

Add `index`, `visible_tree`, `visible_list`, and `paths` functions. Preserve
Maven dependency occurrences by ID and group list entries by coordinate.

**Step 4: Re-run the spec**

Expected: `maven-dependency-model-tests: ok`.

### Task 2: Render the dependency analyzer

**Files:**
- Create: `nvim/lua/custom/maven_dependency_analyzer.lua`
- Test: `nvim/tests/maven_dependency_model_spec.lua`

**Step 1: Add the lazy Maven loader and dependency callback**

Find the current Maven root, lazy load `maven.nvim`, then call
`maven.sources.load_project_dependencies` with an optional force flag.

**Step 2: Add NUI rendering and actions**

Render tree/list/conflict modes from the model. Add filtering, scope and size
toggles, refresh, details, and dependency-path popup actions.

**Step 3: Run model and plugin tests**

Run the Task 1 command and:

```bash
nvim --headless -u NONE "+luafile nvim/tests/maven_plugin_spec.lua" "+qa!"
```

Expected: both specs report their success markers.

### Task 3: Register and document the feature

**Files:**
- Modify: `nvim/init.lua`
- Modify: `nvim/lua/key-map.lua`
- Modify: `nvim/tests/maven_plugin_spec.lua`
- Modify: `nvim/MAVEN.md`

**Step 1: Register command and keymap**

Call analyzer setup during startup and map `<leader>oD` to open it.

**Step 2: Document controls**

Add command, keymap, modes, filters, refresh, details, and limitations to the
Maven usage guide.

**Step 3: Run focused regressions**

Run all Maven specs plus `git diff --check`.
