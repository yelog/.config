# Heirline Buffer Tab Spacing Design

## Goal

Separate adjacent buffer tabs so a file icon does not visually attach to the filename of the buffer on its left, while ensuring the active-tab background is a suitable color from the current theme.

## Current State

`TablineBufferBlock` owns literal-space padding and currently uses `CursorLine.bg` for active buffers. `CursorLine` is intentionally a low-contrast current-row surface: in TokyoNight night it is `#292e42` against `TabLine` `#16161e`, while JB uses `#1f2024` against `#191a1c`. Neither makes the active buffer sufficiently distinct.

## Design

Keep the existing parent component and change its `tabline_background` resolver. Active buffers use `PmenuSel.bg`, the theme's selected-item surface, which has clearer but restrained contrast in both supported themes. If unavailable, the resolver falls back in order to `TabLineSel.bg`, `CursorLine.bg`, and `TabLine.bg`. Inactive buffers use `TabLine.bg`.

Remove the nested filename block's background assignment so it inherits the parent background alongside the icon, flags, and two padding cells. The `FileIcon` provider remains unchanged, retaining its single-cell gap before the current buffer's filename. No foreground colors, click handlers, Git-status logic, or tab-selection behavior change.

## Verification

- Validate the Lua configuration with headless Neovim.
- Confirm the buffer block contains literal-space children on both sides.
- Confirm its dynamic highlight uses `PmenuSel.bg` for active buffers and `TabLine.bg` otherwise.
- Confirm missing primary colors fall back through `TabLineSel.bg`, `CursorLine.bg`, and `TabLine.bg` in order.
- Check the final diff is limited to the design record, tabline component, and regression test.
