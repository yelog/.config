# Services Shutdown Dialog Design

## Goal

Make service shutdown progress visible when Neovim exits by rendering it in a centered floating window.

## Behavior

1. Keep `Q` mapped to `:qa` so failed quits, including unsaved-buffer errors, do not stop services.
2. Reuse the existing `VimLeavePre` lifecycle shutdown flow for all exit paths.
3. Create a centered, non-focusable floating window only when services or Java debug sessions need shutdown.
4. Update the window as graceful shutdown progresses and when forced termination begins.
5. Close the window after shutdown completes. Exits with nothing to stop show no window.
6. Force a UI redraw after each render because exit shutdown waits synchronously.

## Structure

Add a small presentation module responsible only for creating, updating, and closing the floating window. Pass its renderer into `services.lifecycle.setup` from the service bootstrap, leaving lifecycle orchestration and process control unchanged.

## Safety

The dialog is an observer of the existing lifecycle. It must not alter quit ordering, invoke shutdown itself, or steal focus from the active window.
