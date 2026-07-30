# Maven Dependency Remote Refresh Design

## Goal

Provide a keyboard action that regenerates the dependency graph and asks Maven
repository.

## Current Behavior

`r` calls the analyzer with `force=true`, bypassing `maven.nvim`'s dependency
cache. The upstream dependency graph builder does not add Maven's `-U` option,
so Maven retains its normal remote update policy.

## Design

- `r`: force local dependency graph regeneration without `-U`.
- `R`: force graph regeneration with Maven `-U`.
- The analyzer temporarily wraps
  `maven.utils.cmd_builder.build_mvn_dependencies_cmd`, adds `-U` to its command
  args, invokes the existing loader, and immediately restores the original
  builder after command creation. This preserves upstream parsing, caching,
  console output, and error handling while ensuring no unrelated Maven command
  receives `-U`.
- The control rail labels both refresh paths and the notification states whether
  the remote update check is active.

## Testing

Stub the command builder and loader. Assert `R` passes `-U` once, normal and
local forced loads do not, and the builder reference is restored afterward.
