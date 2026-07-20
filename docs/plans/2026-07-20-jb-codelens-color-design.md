# JB CodeLens Color Design

## Goal

Make Java CodeLens text such as `0 references` render as a subdued, unboxed gray in the JB colorscheme.

## Current State

Neovim renders jdtls reference counts through the `LspCodeLens` highlight group. JB maps that group to `General_PopupsAndHints_CodeLens`, which defines only an underline and its special color (`sp=#868A91`). Because it has no foreground color, Neovim falls back to `Normal.fg` (`#BCBEC4`). Java class names use the same effective foreground through `@type`, so the CodeLens text and class name appear identical.

## Design

Extend the existing `JBTheme` `ColorScheme` callback in the JB plugin specification. After JB has defined `LspCodeLens`, read its resolved attributes, replace only its foreground with JB's no-background hint gray (`#727782`), and set the group back. This preserves the theme's existing underline and special underline color.

The override runs only when the `jb` colorscheme loads. Other colorschemes retain their own CodeLens styling, and reloading JB reapplies the override after its palette clears and recreates highlights.

## Scope

- Do not change jdtls CodeLens refresh behavior or Java LSP settings.
- Do not modify the installed `jb.nvim` plugin palette.
- Do not add a background to CodeLens text.

## Verification

- A headless Neovim spec forces the JB colorscheme and asserts the CodeLens foreground, underline, and underline color.
- A full configuration load completes without errors.
- `git diff --check` reports no whitespace errors.
