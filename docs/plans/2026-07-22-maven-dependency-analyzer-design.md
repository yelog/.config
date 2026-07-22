# Maven Dependency Analyzer Design

## Goal

Provide a keyboard-first Maven dependency analyzer for Neovim with a complete
tree, deduplicated list, conflict-only view, live filtering, scope filtering,
JAR sizes, refresh, and dependency paths.

## Architecture

The analyzer is a local extension in `nvim/lua/custom`; it does not change the
vendored development checkout of `oclay1st/maven.nvim`. It calls the existing
`maven.sources.load_project_dependencies` API, retaining its Maven invocation,
cache, conflict parsing, duplicate detection, JAR size lookup, and Console
errors.

`custom.maven_dependency_model` is a dependency-free data model. It indexes
nodes by occurrence and coordinate, selects visible tree paths, produces
deduplicated list entries, and resolves every path to a coordinate.
`custom.maven_dependency_analyzer` renders the selected model with NUI.

## Interaction

- `:MavenDependencies` opens analysis for the Maven project containing the
  current buffer.
- `<leader>oD` opens the same analyzer.
- `t`, `l`, and `c` select tree, list, and conflict-only modes.
- `/` edits the filter; matching includes groupId, artifactId, version, and
  scope. Tree mode retains ancestors of matching nodes.
- `T` hides test-scope dependencies; `S` shows or hides JAR sizes.
- `r` forces Maven resolution; `p` shows every transitive path to the selected
  coordinate; `i` shows dependency details; `Enter` expands tree nodes.

## Error Handling

The command lazily loads `maven.nvim`, verifies a POM can be found, and uses
the existing Maven Console for resolution output. Load failures keep the
Console-visible Maven error and issue a concise notification. Empty results
produce an informative notification rather than an empty popup.

## Test Strategy

Headless specs cover index construction, tree ancestor preservation while
filtering, deduplicated list selection, conflict-only filtering, test-scope
hiding, and all path resolution. Command registration and the keymap are
covered by the existing Maven plugin spec.
