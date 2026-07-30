# Maven Module Dependency Analysis Design

## Goal

Make `<leader>oD` analyze the nearest Maven module POM for the current buffer
and present filtered dependency paths with the context and feedback needed to
match IntelliJ IDEA's dependency analyzer behavior.

## Root Cause

`find_project_root()` prioritizes the enclosing Git or Maven-wrapper root. For
files in `moss-service-common-server`, that resolves to `moss-cloud`, so the
analyzer loads the aggregator POM instead of the active module POM. The
existing tree filter correctly retains a matching dependency and its ancestors,
but `fastjson` is absent from the incorrectly selected graph.

## Architecture

Add a dedicated POM locator to `custom.maven_profiles`. It returns the current
buffer when it is a `pom.xml`; otherwise, it walks upward to the nearest
directory containing `pom.xml`. Keep `find_project_root()` unchanged because
the dashboard and reactor actions intentionally operate on a workspace root.

The dependency analyzer receives the exact POM path, derives its working
directory from that path, and passes the POM path to `maven.sources`. It derives
a display name from the POM's `artifactId`, falling back to the module directory
name if parsing fails. The pure dependency model exposes matched node IDs so the
renderer can distinguish matching artifacts from their retained ancestor path.

## UI And Interaction

- The header identifies the active module: `Maven Dependencies: <artifactId>
  [Tree]`, followed by a secondary `pom: <path>` line.
- `/` filters groupId, artifactId, version, and scope. Tree mode contains every
  match and its path from the module root; matching rows use the `Search`
  highlight and ancestors remain visually subdued.
- Empty filtered trees render `No dependencies match "<query>" in
  <artifactId>` instead of leaving the popup blank.
- Existing keyboard controls remain stable: `t`, `l`, `c`, `/`, `T`, `S`, `r`,
  `p`, `i`, `Enter`, and `q`.

## Error Handling

If no nearest POM exists, notify the user and do not open the popup. If the POM
cannot be read for its display name, analyze it normally and use the directory
name. Dependency-resolution failures remain visible through the upstream Maven
console and receive the existing concise notification behavior.

## Test Strategy

- Verify nearest-POM selection for a POM buffer and a nested source file.
- Verify the analyzer passes the exact POM path to Maven resolution.
- Verify filtered trees preserve all ancestors and identify matching nodes.
- Verify a query with no matching dependency renders the explicit empty state.
- Run existing Maven model, analyzer, and plugin headless specs plus
  `git diff --check`.
