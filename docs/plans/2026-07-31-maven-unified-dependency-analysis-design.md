# Maven Unified Dependency Analysis Design

## Goal

Provide one Maven dependency analysis experience while retaining the upstream
plugin as the provider for Maven execution, dependency resolution, caching,
and project discovery.

## Decision

Keep `oclay1st/maven.nvim` as infrastructure. Its project panel remains the
Maven navigation surface, but its built-in dependency view is no longer a
user-facing entry point. The local dependency analyzer is the sole dependency
analysis UI.

## Entry Points

- `<leader>oD` and `:MavenDependencies` resolve the nearest POM for the
  current buffer, then open the local analyzer.
- In the Maven project panel, `a` resolves the currently selected tree node to
  its owning project and opens the local analyzer for that project's exact
  `pom_xml_path`.
- A project root, module folder, lifecycle node, dependency node, or other
  project-owned node all analyze their owning module. This preserves the
  existing upstream `a` semantics while making the target explicit.

## Architecture

`custom.maven_project_tree` already adapts upstream project-tree behavior in a
local, idempotent install hook. It will also wrap the upstream project-view
keymap setup: run the original setup first, then replace the buffer-local `a`
mapping. The replacement retrieves the selected node and project through the
upstream view, validates selection, and calls
`custom.maven_dependency_analyzer.open(false, false, project.pom_xml_path)`.

The analyzer already accepts an explicit POM path and delegates loading to
`maven.sources.load_project_dependencies`; no new Maven parser, cache, or
command runner is introduced. The upstream `DependenciesView` remains
installed but unreachable from normal configuration entry points.

## Error Handling

With no selected project-tree node, `a` retains the upstream warning behavior
and opens no view. All POM validation, Maven loading failures, empty dependency
results, and refresh behavior remain owned by the local analyzer.

## Testing

Add adapter coverage with a stub upstream project view and a stub analyzer.
Verify installation is idempotent, `a` delegates the selected module POM, and
an empty selection notifies without calling the analyzer. Retain existing
analyzer, model, plugin, and project-tree specs as regressions.
