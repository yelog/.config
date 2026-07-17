# Resession Autosave Design

## Goal

Keep periodic session recovery while removing repeated `Saved session` messages
and reducing session writes.

## Configuration

`stevearc/resession.nvim` remains enabled. Its autosave interval changes from
60 seconds to 300 seconds and its notifications are disabled.

The existing `VimLeavePre` callback remains unchanged. It silently creates or
updates the directory-scoped session on normal exit, including for directories
without a previously restored session.

## Verification

The existing Resession configuration spec will assert that autosave remains
enabled, runs every 300 seconds, and does not notify. The focused headless spec
will validate the change without writing a real session.
