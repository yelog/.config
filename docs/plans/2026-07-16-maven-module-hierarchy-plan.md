# Maven Module Hierarchy Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild `maven.nvim` project trees from explicit Maven module declarations so child POMs never appear as duplicate top-level projects.

**Architecture:** Keep `oclay1st/maven.nvim`'s scanner intact and install a local wrapper around its exported `maven.sources.scan_projects` function. The wrapper normalizes the completed project graph by flattening discovered objects, resolving explicit module POM paths, removing cyclic links, reattaching modules, and returning only unreferenced roots.

**Tech Stack:** Neovim 0.11, Lua, `oclay1st/maven.nvim`, headless Neovim specs.

---

### Task 1: Add the Hierarchy Regression Spec

**Files:**
- Create: `nvim/tests/maven_project_tree_spec.lua`
- Reference: `nvim/tests/maven_plugin_spec.lua:1-67`
- Reference: `nvim/lua/custom/maven_project_tree.lua` (new)

**Step 1: Write the failing hierarchy test**

Load `custom.maven_project_tree` with `nvim/lua` on `package.path`. Construct plain project tables in child-first order:

```lua
local root = project("/workspace/pom.xml", "/workspace", "root")
local api = project("/workspace/api/pom.xml", "/workspace/api", "api")
local service = project("/workspace/api/service/pom.xml", "/workspace/api/service", "service")
local cli = project("/workspace/cli/pom.xml", "/workspace/cli", "cli")
```

Pass a parser stub whose module paths are:

```lua
{
  ["/workspace/pom.xml"] = { "api", "cli" },
  ["/workspace/api/pom.xml"] = { "service" },
}
```

Assert that `rebuild({ service, cli, api, root }, parser)` returns only `root`,
that `root.modules` is `{ api, cli }`, and that `api.modules` is `{ service }`.

Also assert that a POM referenced by two aggregators is attached once and that
a two-POM cycle produces two top-level roots rather than recursive modules.

**Step 2: Run the test to verify it fails**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_project_tree_spec.lua" "+qa!"
```

Expected: failure because `custom.maven_project_tree` does not exist.

### Task 2: Implement the Runtime Hierarchy Adapter

**Files:**
- Create: `nvim/lua/custom/maven_project_tree.lua`
- Test: `nvim/tests/maven_project_tree_spec.lua`
- Reference: `/Users/yelog/.local/share/nvim/lazy/maven.nvim/lua/maven/sources/init.lua:63-105`
- Reference: `/Users/yelog/.local/share/nvim/lazy/maven.nvim/lua/maven/parsers/pom_xml_parser.lua:15-45`

**Step 1: Add pure graph rebuilding**

Expose `M.rebuild(projects, parse_file)` where `parse_file` defaults to
`require("maven.parsers.pom_xml_parser").parse_file`. The function must:

1. Recursively collect every object in `projects` into a map keyed by normalized
   `pom_xml_path`, using a seen set to avoid duplicate objects.
2. Reset every collected `project.modules` list.
3. Build a candidate adjacency map from each parsed `module_paths` entry by
   first resolving `vim.fs.normalize(vim.fs.joinpath(project.root_path,
   module_path))` against discovered POM paths, then falling back to that path
   with `pom.xml` appended.
4. Exclude any edge whose child can already reach its parent in the candidate
   graph, so cyclic Maven declarations remain roots.
5. Sort parents by normalized POM path, attach each eligible child once, and
   record attached module POM paths.
6. Return unattached projects as roots after recursively sorting every level by
   `string.lower(project.name)`.

Use direct table insertion for modules; the adapter must work with the
upstream `Project` class and plain project fixtures.

**Step 2: Add idempotent scanner installation**

Implement `M.install()` that requires `maven.sources` once, stores its existing
`scan_projects`, and replaces it with:

```lua
function(base_path, callback)
  return upstream_scan_projects(base_path, function(projects)
    callback(M.rebuild(projects))
  end)
end
```

Do not patch Lazy-installed plugin files. Preserve callback timing and the
upstream scanner's return value.

**Step 3: Run the focused spec**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_project_tree_spec.lua" "+qa!"
```

Expected: `maven-project-tree-spec-tests: ok`.

### Task 3: Install the Adapter With Maven

**Files:**
- Modify: `nvim/lua/plugins/panel/maven.lua:13-16`
- Modify: `nvim/tests/maven_plugin_spec.lua:21-51`

**Step 1: Extend the plugin spec**

Stub `custom.maven_project_tree.install` alongside the existing Maven and
profile-helper stubs. After calling the plugin specification's `config`, assert
that the adapter installs once after `maven.setup` and before profile state is
applied.

**Step 2: Load the adapter after upstream setup**

Change the lazy plugin `config` function to:

```lua
require("maven").setup(opts)
require("custom.maven_project_tree").install()
require("custom.maven_profiles").apply_current()
```

This ordering guarantees the upstream source table exists before it is wrapped.

**Step 3: Run focused specs**

Run:

```bash
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_project_tree_spec.lua" "+qa!"
nvim --headless -u NONE "+luafile /Users/yelog/.config/nvim/tests/maven_plugin_spec.lua" "+qa!"
```

Expected: both specs report success.

### Task 4: Run Final Validation

**Files:**
- Verify: `docs/plans/2026-07-16-maven-module-hierarchy-design.md`
- Verify: `nvim/lua/custom/maven_project_tree.lua`
- Verify: `nvim/lua/plugins/panel/maven.lua`
- Verify: `nvim/tests/maven_project_tree_spec.lua`
- Verify: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Run all headless specs**

Run:

```bash
zsh -lc 'for test in "$PWD"/tests/*_spec.lua; do nvim --headless -u NONE "+luafile $test" "+qa!" || exit 1; done'
```

from `/Users/yelog/.config/nvim`.

Expected: every spec exits successfully.

**Step 2: Check formatting**

Run:

```bash
stylua --check nvim/lua/custom/maven_project_tree.lua nvim/lua/plugins/panel/maven.lua nvim/tests/maven_project_tree_spec.lua nvim/tests/maven_plugin_spec.lua
```

from `/Users/yelog/.config`.

Expected: no formatting errors.

**Step 3: Inspect the scoped diff**

Run:

```bash
git diff -- docs/plans/2026-07-16-maven-module-hierarchy-design.md docs/plans/2026-07-16-maven-module-hierarchy-plan.md nvim/lua/custom/maven_project_tree.lua nvim/lua/plugins/panel/maven.lua nvim/tests/maven_project_tree_spec.lua nvim/tests/maven_plugin_spec.lua
```

Expected: only the documented hierarchy adapter, configuration integration, and
regression coverage appear. Do not commit unless explicitly requested.
