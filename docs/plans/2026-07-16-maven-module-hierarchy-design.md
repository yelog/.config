# Maven Module Hierarchy Design

## Goal

Render Maven reactor projects as a hierarchy based on each aggregator POM's
`<modules>` declarations. A module must appear only beneath its owning
aggregator, not again as a top-level project.

## Root Cause

`oclay1st/maven.nvim` scans every `pom.xml` recursively and immediately builds
each discovered project. Its module builder skips a module POM that has already
been scanned. When the filesystem yields a child directory before its parent
`pom.xml`, the child becomes a top-level project first and cannot be attached
when the aggregator is scanned later.

`project_scanner_depth` only limits directory discovery. It does not determine
or correct parent-before-child project construction.

## Scope

- Add a local runtime adapter after `maven.nvim` setup.
- Rebuild project-module relationships from the discovered POM files after the
  upstream scanner finishes.
- Show only projects that are not referenced by another discovered POM at the
  top level.
- Preserve independent aggregators and standalone projects under the workspace.
- Keep project and module ordering stable by sorting them by display name.
- Apply the same result to the Projects and Favorites views because both use
  `maven.sources.scan_projects`.

## Non-Goals

- Do not edit files in Lazy's installed plugin directory.
- Do not fork `oclay1st/maven.nvim`.
- Do not change Maven invocation, selected Profiles, command execution, or
  dependency loading.
- Do not infer Maven 4 automatic subprojects when no explicit `<modules>` list
  exists.

## Architecture

`nvim/lua/custom/maven_project_tree.lua` installs the adapter once at runtime.
It retains the upstream scanner, wraps its callback, and normalizes the returned
project graph before the UI receives it.

The adapter performs these steps:

1. Recursively collect every upstream `Project` object into a map keyed by its
   normalized `pom_xml_path`.
2. Clear all existing `modules` lists so incidental scan order no longer affects
   the result.
3. Parse each collected POM's explicit module paths and first resolve a direct
   POM reference such as `<module>child/pom.xml</module>`, then fall back to the
   conventional `<module>/pom.xml` path.
4. Reattach a collected project beneath the POM that declares it as a module.
5. Return only projects that were not attached as a module, with each level
   sorted by project name.

The adapter is intentionally narrow: it works with the plugin's public source
table and existing project data instead of copying or patching upstream files.

## Error Handling

- If a declared module POM is outside scanner results, it is ignored just as the
  upstream scanner ignores an unreadable module POM.
- If a malformed POM causes upstream scanning to fail, the adapter does not
  suppress or reinterpret that error.
- A module referenced more than once is attached only once, preventing duplicate
  tree nodes.
- Cyclic declarations are left as top-level projects rather than creating an
  infinite recursive hierarchy.

## Verification

- Add a focused headless spec using a reactor POM tree whose children are
  supplied to the adapter before the aggregator.
- Assert that only the aggregator remains at top level.
- Assert direct and nested module ordering and relationships.
- Run the existing Maven plugin and profile specs plus the full headless test
  suite.
