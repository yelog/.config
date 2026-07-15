# Services Shutdown Design

## Goal

On a normal Neovim exit, terminate every process managed by the Services runtime, including ordinary descendants started by Maven, Gradle, npm, or shell wrappers. Active Java Debug sessions must receive a DAP termination request and their integrated terminal job must be stopped if the request does not finish within the grace period.

## Approach

Each POSIX service command is spawned with `vim.system(..., { detach = true })`. Libuv makes that child a process-group leader, so its process group contains the command and normal descendants. The runtime stores a process wrapper whose `kill(signal)` sends the signal to `-pid` with `vim.uv.kill`. Non-POSIX platforms retain direct-PID termination as a safe fallback.

All existing runtime lifecycle paths use the wrapper, so manual stop, restart, disposal, and shutdown share the same process-tree behavior.

## Exit Flow

`VimLeavePre` is registered once during Services plugin initialization. Its callback:

1. marks the runtime as shutting down, which prevents pending or failed services from restarting;
2. cancels restart and health-check timers;
3. starts Java Debug termination and sends `SIGTERM` to every active service process group;
4. waits up to three seconds while Neovim processes exit callbacks;
5. sends `SIGKILL` to remaining managed process groups and force-stops an active Java Debug terminal job.

The callback issues no explicit notifications and is idempotent, so multiple exit paths do not duplicate signals.

## Java Debug

`custom.java_debug` exposes shutdown helpers. The graceful helper cancels an in-flight build and requests DAP termination with `terminateDebuggee = true`. The forced helper stops the active integrated-terminal job and sends `SIGKILL` to its PID when available. This preserves the existing terminal output archive behavior for ordinary user-initiated termination.

## Boundaries

The guarantee applies to normal Neovim exit on POSIX systems and processes that remain in their managed process group. Processes intentionally daemonized with `nohup`, `setsid`, `docker compose up -d`, or similar mechanisms cannot be recovered reliably by Neovim. Neither can processes after `kill -9 nvim` or host shutdown.

## Verification

- Runtime tests cover shutdown signals, pending-restart cancellation, and group retention after a leader exits before a TERM-ignoring child.
- Real-process smoke tests verify both ordinary shell descendants and TERM-ignoring descendants are removed.
- Lifecycle tests verify one `VimLeavePre` hook, the shared grace period, and forced descendant cleanup through that hook.
- Java Debug tests verify POSIX process-group use for build preparation and safe idle shutdown helpers.
