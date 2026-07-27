# Services Log Clear Design

## Goal

Allow users to clear the currently selected service's in-memory log from either
the Services list or its normal log window without stopping the service or
interrupting future output.

## Current Behavior

`services.output.Output:clear()` already resets rendered lines, ANSI extmarks,
pending lines, and stream parsing state. `services.runtime.Runtime:reset_output`
also clears an output renderer, but exposes the action as an output replacement.
The Services panel has no keybinding or help entry for either operation.

## Design

Add an explicit `Runtime:clear_output(key)` operation. It will clear the
service's standard renderer and emit an `output_cleared` event. This keeps the
user-facing operation distinct from output-buffer replacement and lets every
panel displaying the same service synchronize its UI state.

Map `c` in both the Services list buffer and standard Services log buffers. The
action targets the service selected in the list, or the service shown in the
active log window. Terminal-backed output is not clearable through this action;
the panel will show a concise warning instead of modifying the terminal buffer.

On `output_cleared`, each relevant panel will reset that service's follow state:
follow is enabled, the unread count becomes zero, and any stored paused view is
discarded. The output winbar therefore returns to `LOG [FOLLOW]`. Focus remains
where the user invoked the command. New process output continues to append to
the same renderer normally.

## User Experience

- `c` in the service list clears the cursor-selected service's log.
- `c` in a standard Services log window clears the displayed service's log.
- `?` documents `c` alongside the existing service controls.
- Clearing is immediate and requires no confirmation because it affects only
  ephemeral, session-local output.
- Clearing neither stops nor restarts a process and does not alter the 10,000
  line retention policy.

## Verification

- Runtime tests verify that clearing removes rendered log lines and emits
  `output_cleared` while retaining the same standard output buffer.
- Panel tests verify list and log-window mappings, state reset, focus retention,
  and subsequent live output.
- Existing Services output, runtime, and panel specifications remain green.

## Non-goals

- Persisting logs or recovering cleared output.
- Clearing terminal buffers.
- Confirmation dialogs, filtering, or log export.
