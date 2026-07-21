# Maven Reactor Lifecycle Design

## Goal

Let a lifecycle phase invoked on an aggregator project in the Maven Projects
panel build its complete reactor, including every discovered descendant module.

## Root Cause

The installed `oclay1st/maven.nvim` command builder always adds Maven's `-N`
(`--non-recursive`) option.  Its Projects view uses that builder for every
lifecycle node, so selecting `compile` on an aggregator runs only that POM.

## Scope

- Patch only the Projects view lifecycle execution handler at runtime.
- For a project with one or more resolved `modules`, remove `-N` from the
  generated lifecycle command.
- Keep `--file=<selected pom>` so Maven starts from the selected aggregator.
- Preserve upstream behavior for leaf projects and all non-lifecycle paths.

## Non-Goals

- Do not edit the Lazy-installed plugin or fork it.
- Do not alter `:MavenExec`, dependency loading, plugin goals, custom commands,
  favorites, profiles, or the project-tree scanner.
- Do not infer aggregation from POM content when the panel has no child nodes.

## Architecture

A new `custom.maven_reactor_execution` adapter exposes a pure command helper
and an idempotent `install()` function.  The helper delegates command creation
to the upstream builder, removes only the exact `-N` argument when the selected
project has child modules, and otherwise returns the command untouched.

`install()` replaces `maven.ui.projects_view`'s private lifecycle handler with
the upstream-equivalent implementation, except that it calls the helper before
passing the command to the upstream console.  The existing project-tree adapter
continues to define `project.modules`, so execution follows the same hierarchy
the user sees.

## Error Handling

- A missing or malformed `modules` list is treated as a leaf project.
- If the upstream builder changes shape, no command arguments besides exact
  `-N` are changed.
- Repeated plugin configuration does not wrap the lifecycle handler again.

## Verification

- Add headless tests for aggregator and leaf command construction.
- Add an installation test proving the patched handler dispatches a recursive
  aggregator command and leaves leaf commands non-recursive.
- Run the Maven panel and hierarchy specs.
