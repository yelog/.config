# Maven Dependency Refresh Context Design

## Goal

Make dependency refresh shortcuts reliably operate on the Maven module already
represented by the open dependency panel.

## Root Cause

The panel buffer is a `nofile` buffer. Its `r` and `R` mappings called
`M.open()` without a POM path, causing it to look up the nearest POM from that
temporary buffer and report that none exists.

## Design

`Analyzer` owns the exact `pom_path` used to create its dependency graph. Its
refresh mappings pass that path into `M.open()`. `M.open()` accepts an optional
POM path and only performs current-buffer discovery for external commands such
as `<leader>oD` and `:MavenDependencies`.

Both local `r` and remote `R` refreshes therefore target the panel's module
regardless of the active editor window or temporary buffer state.

## Testing

Make the POM locator fail after the panel is mounted, then trigger remote
refresh. Assert resolution still receives the original module POM.
