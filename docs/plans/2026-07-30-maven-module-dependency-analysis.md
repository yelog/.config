# Maven Module Dependency Analysis Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Analyze the closest Maven module POM and make filtered dependency
trees explain both matches and their transitive paths.

**Architecture:** Leave workspace-root discovery unchanged for the Maven
dashboard. Add a nearest-POM locator for the dependency analyzer, pass that
exact POM to upstream dependency resolution, and add pure model metadata for
the renderer's match state and empty state.

**Tech Stack:** Neovim Lua, `MunifTanjim/nui.nvim`, `oclay1st/maven.nvim`,
headless Neovim specs.

---

### Task 1: Locate the active module POM

**Files:**
- Modify: `nvim/lua/custom/maven_profiles.lua:139-155`
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua:11-34`

**Step 1: Write the failing test**

Add fixtures for a source file under a nested Maven module and a direct
`pom.xml` buffer. Assert a new locator returns the nested module POM in both
cases rather than the enclosing Git root POM.

**Step 2: Run test to verify it fails**

Run: `nvim --headless -u NONE "+luafile nvim/tests/maven_dependency_analyzer_spec.lua" "+qa!"`

Expected: FAIL because the locator is not present.

**Step 3: Write minimal implementation**

Add a public `find_nearest_pom(path)` that normalizes its input, returns a
current `pom.xml` path directly, or calls `vim.fs.find("pom.xml", { upward =
true, path = path })` and returns the first result.

**Step 4: Run test to verify it passes**

Run the command from Step 2.

Expected: analyzer spec success marker.

### Task 2: Preserve tree filtering metadata

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_model.lua:55-79`
- Modify: `nvim/tests/maven_dependency_model_spec.lua:35-39`

**Step 1: Write the failing test**

Assert filtered tree metadata identifies `shared` occurrences as direct
matches, while their parent occurrences remain visible but are not matches.

**Step 2: Run test to verify it fails**

Run: `nvim --headless -u NONE "+luafile nvim/tests/maven_dependency_model_spec.lua" "+qa!"`

Expected: FAIL because match metadata is absent.

**Step 3: Write minimal implementation**

Expose a `matching_ids(graph, options)` function that applies the existing
matching and scope rules without introducing UI dependencies.

**Step 4: Run test to verify it passes**

Run the command from Step 2.

Expected: `maven-dependency-model-tests: ok`.

### Task 3: Render module context, matches, and empty results

**Files:**
- Modify: `nvim/lua/custom/maven_dependency_analyzer.lua:39-143,234-257`
- Modify: `nvim/tests/maven_dependency_analyzer_spec.lua:11-34`

**Step 1: Write the failing test**

Stub the nearest POM locator and Maven source. Assert `open()` supplies that
exact POM path, and expose renderer behavior sufficient to assert an empty
filtered tree produces an explanatory line.

**Step 2: Run test to verify it fails**

Run: `nvim --headless -u NONE "+luafile nvim/tests/maven_dependency_analyzer_spec.lua" "+qa!"`

Expected: FAIL because the analyzer still constructs `root .. "/pom.xml"`.

**Step 3: Write minimal implementation**

Construct `Analyzer` with `pom_path`, resolve module display name from the POM,
pass `pom_path` to `maven.sources`, add a header POM context line, highlight
matched tree rows with `Search`, and render a no-match message when a filtered
tree has no visible nodes.

**Step 4: Run test to verify it passes**

Run the command from Step 2.

Expected: `maven-dependency-analyzer-tests: ok`.

### Task 4: Run focused regression checks

**Files:**
- Test: `nvim/tests/maven_dependency_model_spec.lua`
- Test: `nvim/tests/maven_dependency_analyzer_spec.lua`
- Test: `nvim/tests/maven_plugin_spec.lua`

**Step 1: Run Maven specs**

Run: `for spec in nvim/tests/maven_dependency_model_spec.lua nvim/tests/maven_dependency_analyzer_spec.lua nvim/tests/maven_plugin_spec.lua; do nvim --headless -u NONE "+luafile $spec" "+qa!" || exit 1; done`

Expected: each test reports its success marker.

**Step 2: Check patch whitespace**

Run: `git diff --check`

Expected: no output and exit code 0.

**Step 3: Commit**

Do not commit unless the user explicitly requests one.
