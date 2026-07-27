# Services Panel Persistent Delete Design

## Goal

Make `dd` permanently remove the selected service from the current project's
Services panel. The service must remain absent after Neovim restarts and may be
added again through `a`.

## Current Behavior

`dd` calls `Panel:dispose_service`, which only removes the service from the
in-memory runtime. The persisted `selected_services` list is unchanged. On the
next panel open, `Panel:open` reconciles discovered definitions against that
list and registers the service again.

## Design

The panel owns this user-facing selection change:

1. Read the current project's selected service keys.
2. Remove the target service key and persist the updated list.
3. If persistence fails, report an error and leave the runtime service intact.
4. If persistence succeeds, use the existing disposal path so stopped services
   are removed immediately and running services are stopped before disposal.

`Runtime:dispose` remains responsible only for runtime resource cleanup. This
keeps temporary runtime cleanup independent of persisted project configuration.

## Verification

Add panel tests for successful persistent removal and failed persistence. Run
the Services panel, state/catalog, and runtime test specifications with
headless Neovim.
