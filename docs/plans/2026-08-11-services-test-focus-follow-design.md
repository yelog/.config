# Services Test Focus and Follow Design

## Goal

When `<leader>jt` starts a Java test, select its services-panel row and keep
its output pane following live Maven and Spring logs.

## Design

- Make `Panel:focus()` synchronize the left list cursor with the requested
  service key after it sets `focused_key` and displays the service output.
- Keep the list window active after synchronization so triggering a test does
  not move focus into the log pane.
- Force the selected service's output state to FOLLOW when a Java test begins
  or reruns. Its existing output-render event then tails every appended batch.
- If a service is absent from the current rendered rows, focus still updates
  the output and returns successfully; it does not move an unrelated cursor.

## Verification

- A focus request moves the list cursor to the matching row and preserves list
  window focus.
- A newly started test has `following=true` before output arrives.
- Appended output moves the test log pane to the final line while the list
  remains active.
