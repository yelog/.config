# Services Panel Focus Restore Design

## Goal

Opening the Services panel focuses its service list. Closing and reopening the panel restores the service that was focused before closing, including its current list row and output buffer.

## Design

Keep the focused service key in the panel controller, indexed by tab page and normalized project root. This state is intentionally session-local: it represents transient UI focus rather than persisted project configuration.

Before closing a panel, remember its `focused_key`. When opening a panel, render the current runtime records, validate the remembered key against the current project, find its current row by key, move the list cursor to that row, and bind its output buffer. Looking up the row after rendering makes restoration independent of status-based service reordering.

Newly opened and restored panels leave Neovim focus in the service-list window. If no valid service was remembered, the output pane remains empty and the cursor stays on the first row.

## Verification

Extend the Services panel headless test to assert initial list focus, close/reopen restoration of the focused service and log buffer, cursor restoration by service key, and isolation from invalid remembered keys.
