# Maven Dependency Workbench Design

## Goal

Turn the Neovim Maven dependency popup into a compact, keyboard-first
dependency workbench with a clear visual hierarchy and the high-frequency
analysis actions needed during everyday dependency maintenance.

## Visual Problems

The existing view flattens module context, controls, and dependency data into
nearly identical monochrome text. Long coordinates make artifact names hard to
scan, state prefixes have no legend, and the large popup leaves most of its
space unused. It exposes raw data but does not provide an at-a-glance answer to
how many direct, resolved, conflicting, or large dependencies the module has.

## Visual System

The popup has three compact regions:

1. Identity: module name, active mode, and relative POM path.
2. Overview and controls: direct/resolved/conflict/size statistics plus a
   concise keyboard command rail whose active state is visibly emphasized.
3. Dependency data: tree affordances and metadata are subdued; artifactId is
   primary; version, scope, groupId, and size are progressively secondary.

Use existing semantic highlight groups rather than fixed colors so the design
adapts to the user's theme. Direct roots receive a `D` marker, duplicate nodes
receive `=`, conflicts receive `!`, and search matches use `Search`.

## Product Capabilities

- `g`: toggle groupId visibility. Artifact names remain the primary scan target.
- `s`: sort current roots, siblings, or list entries by resolved JAR size.
- `o`: for a direct dependency, close the popup, open the active module POM,
  and position the cursor on its artifactId declaration. Transitive dependencies
  direct users to `p` for provenance instead of pretending there is a local
  declaration.
- Summary statistics: direct root count, resolved occurrence count, conflict
  count, and aggregate resolved size.
- Existing tree/list/conflict modes, filter, test hiding, sizes, paths, details,
  and refresh remain stable.

## Architecture

Keep graph derivations in `maven_dependency_model`: `summary` calculates the
overview and `ordered_ids` provides a stable size-aware order. The analyzer
stores presentation state (`show_group_id`, `sort_by_size`), delegates data
selection to the model, and renders with NUI Lines. POM navigation remains in
the analyzer because it owns the active POM path and popup lifecycle.

## Testing

Model specs cover summary counts and stable descending size order. Analyzer
specs verify the new controls render and POM navigation only accepts direct
dependencies. Existing focus, filtering, and expansion tests remain intact.
