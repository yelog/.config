# Services Shutdown Feedback Design

## Goal

Make the short wait during Neovim exit understandable by showing that Services
is intentionally shutting down Java and other managed processes.

## User Experience

During a pending graceful shutdown, render one transient command-area message:

```text
◐ 正在关闭服务 2/3 · 1.2s
```

The spinner advances on the lifecycle's existing 20 ms wait polling interval,
focus, or invite interaction. It is cleared when shutdown completes.

If graceful shutdown reaches its timeout, replace the message with a short
`正在强制关闭剩余服务…` status before existing force termination runs.

## Architecture

`services.lifecycle` already owns the shared graceful timeout for the runtime
and Java debug manager. It will also own feedback:

1. Count pending runtime services and a pending Java debug manager before
   waiting.
2. During each wait predicate, re-evaluate completion and render the current
   count, spinner frame, and elapsed time.
3. Clear feedback after normal completion or after force shutdown.

The renderer is injectable through lifecycle options so the test suite verifies
text and state transitions without relying on a visible UI. The default uses
`nvim_echo` followed by `:redraw` to make feedback visible during `VimLeavePre`.

## Error Handling And Verification

Feedback is best-effort: UI redraw errors must not block shutdown. Tests cover
completed shutdowns, pending progress, timeout escalation, and cleanup. Existing
runtime and Java shutdown behavior remains unchanged.
