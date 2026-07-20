# Services Log Follow Design

## Goal

Make the Services output pane follow live logs by default without interrupting
users who scroll or search earlier output. Returning to the bottom of the log
automatically restores live follow mode.

## Current Behavior

`services.output` appends rendered log batches to a `nofile` buffer, applies
ANSI extmarks, and trims the buffer to its retention limit. It does not update
the view of any window showing that buffer. `services.panel` binds the selected
service buffer to its output window but has no follow or paused-view state.

As a result, new output is retained but the visible window stays at its former
position. Native Neovim search works, but there is no protection against a
future follow implementation disrupting a search result.

## Design

Each Services panel will retain view state per service output: whether the
output is following live logs and how many rendered lines arrived while it was
paused. The state is session-local UI state and will not be persisted in the
service catalog.

The selected service starts in follow mode. A rendered output batch moves only
the matching panel output window to its latest line when that state is still
following. The move is performed in the target window context so it never
steals focus from the editor or service list.

Scrolling away from the bottom, moving to an older log line, or starting a
forward or backward search changes the state to paused. While paused, batches
continue to append to the existing buffer and update an unread line count, but
they do not move the cursor or viewport. Native `/`, `?`, `n`, and `N` remain
the search interface.

When the viewport reaches the end of the buffer, including through Neovim's
native `G` or `Ctrl-End` motions, the state returns to follow mode and clears
the unread count. This satisfies both continuous monitoring and history search
without a separate mode-switch command.

The output window winbar will make the state visible with concise text such as
`LOG [FOLLOW]` or `LOG [PAUSED - 18 new - G tail]`.

## Components

### Output renderer

`nvim/lua/services/output.lua` will report completed render batches after the
buffer and ANSI extmarks are updated. The event payload will include the number
of appended lines, retained line count, and any lines trimmed by the configured
retention limit.

### Runtime event forwarding

`nvim/lua/services/runtime.lua` will translate the renderer callback into a
dedicated `output_rendered` service event. This event is distinct from service
metadata updates so a high-volume log stream does not re-render the service
list for every batch.

### Panel follow controller

`nvim/lua/services/panel.lua` will handle `output_rendered` only for the
currently displayed service. It will track follow state, detect leaving or
returning to the output bottom through window and cursor events, pause before
search input, update the winbar, and advance the output window only while
following.

All window and buffer operations will validate that the panel, output window,
and selected buffer are still live. A closed panel or a switched service must
turn an output event into a no-op.

## Retention

The existing default limit of 10,000 retained log lines remains unchanged.
Search applies to retained buffer content only. If trimming happens while a
user is paused, the controller must not force a jump to the newest line.

## Verification

- A visible output pane at the tail follows a newly rendered batch without
  moving Neovim focus away from the current editor or service list.
- Scrolling or moving to older output pauses follow; a later batch preserves
  the cursor and viewport and increments the unread indicator.
- Starting `/` or `?` pauses before the search command can be interrupted.
- Moving to the last log line resumes follow and clears the unread indicator.
- Output render events do not re-render the services list.
- Buffer retention trimming does not force a paused view to the tail.
- Existing Services output, runtime, and panel tests remain green.

## Non-goals

- Persisting full service logs to disk or searching output evicted by retention.
- A custom fuzzy-search UI, log filtering, log-level controls, or stack-trace
  navigation.
- Changing process lifecycle, ANSI decoding, or service discovery behavior.
