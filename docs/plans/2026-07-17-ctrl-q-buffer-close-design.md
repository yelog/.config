# Ctrl-Q Buffer Close Design

## Goal

Make `<C-q>` delete the current file buffer without closing its Neovim window. The behavior must preserve Services and Maven split layouts.

## Decision

Map `<C-q>` to `Snacks.bufdelete()` for ordinary buffers. Keep the existing behavior of closing Neo-tree when Neo-tree itself has focus.

`Snacks.bufdelete()` prompts for unsaved changes, replaces the deleted buffer in every window that shows it, and only then deletes the buffer. This avoids the native `:bdelete` behavior that closes windows displaying the active buffer.

## Scope

- Remove the split-geometry-dependent `<C-q>` implementation and its private `split_type` helper from `nvim/lua/key-map.lua`.
- Preserve the focused Neo-tree exception without allowing an open Neo-tree window to affect `<C-q>` in a code window.
- Keep all other keymaps and panel behavior unchanged.

## Verification

Run a headless Neovim scenario with a code buffer and a panel split. Trigger the `<C-q>` callback equivalent and assert that both windows remain while the code buffer is replaced.
