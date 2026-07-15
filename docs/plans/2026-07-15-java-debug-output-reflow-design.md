# Java Debug Output Reflow Design

## Goal

Make live Java Debug output use the same normal Services log buffer as regular service output so it soft-wraps and reflows when the Services pane or Snacks zoom width changes.

## Current Behavior

Java Debug sets `console = "integratedTerminal"`. nvim-dap starts a terminal job and `custom.java_debug` replaces the focused service's normal output buffer with that terminal buffer. Terminal output is a PTY grid, so its scrollback cannot be fully reflowed after horizontal resize. The current code archives it into a normal buffer only after the session ends.

## Design

Default Java service debug launches to `internalConsole`. The Java Debug Adapter emits DAP `output` events for this console, and an nvim-dap `after.event_output` listener routes events for the active Java service session into the existing `services.output` renderer.

The renderer already strips ANSI controls for parsers, preserves ANSI style spans, retains bounded history, and uses `wrap=true` plus `linebreak=true`. No terminal buffer is created in the default path, so output is immediately searchable and reflows at any window width.

`services.runtime` gains two narrow operations:

- reset a service to its normal output buffer and clear prior content before a debug launch;
- append a DAP output chunk to the named output stream.

The listener maps DAP `stderr` events to the stderr stream and all other categories to stdout. It only routes events belonging to the active service's `internalConsole` session. nvim-dap's normal REPL handling remains intact because the route is an `after` listener.

## Integrated Terminal Fallback

Project configuration retains precedence through `.nvim/java-debug.json`. A project that needs `System.in` can set:

```json
{
  "defaults": {
    "console": "integratedTerminal"
  }
}
```

The existing terminal adoption and post-session archive paths remain available for this explicit fallback.

## Verification

- Runtime tests cover output reset and DAP-style append behavior.
- Java Debug tests cover the default console, stdout/stderr routing, ANSI rendering, and integrated-terminal override preservation.
- Existing zoom and Java Debug tests continue to pass.
