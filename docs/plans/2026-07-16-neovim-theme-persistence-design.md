# Neovim Theme Persistence Design

## Goal

Restore the most recently selected colorscheme for every Neovim launch mode, including launches with a directory or file argument.

## Current State

The TokyoNight specification unconditionally runs `:colorscheme tokyonight` during plugin setup. A manual `:colorscheme jb` affects only the current process. Resession restores directory sessions only when Neovim starts without arguments, and its configured options are currently discarded because the plugin setup call omits `opts`.

## Design

Create `custom.theme`, a small global state module stored under `stdpath("state")`. It records the colorscheme name and `background` whenever `ColorScheme` fires. After Lazy finishes loading the installed theme plugins, it restores the saved colorscheme with the Neovim command API. Invalid or unavailable saved names fall back to TokyoNight without aborting startup.

Theme restoration is deliberately global. Resession's built-in colorscheme extension remains disabled because it restores a per-directory session value and could override the globally most recent choice. Its existing options are still passed to `resession.setup(opts)`, fixing the current autosave configuration bug.

TokyoNight continues to register its palette and highlight overrides, but no longer chooses the active colorscheme itself. `custom.theme` becomes the single owner of the startup default and persisted choice.

## Verification

- A headless module spec restores a saved builtin colorscheme, persists a later `ColorScheme` event, and falls back when state is malformed or names an unavailable theme.
- A focused Resession spec confirms the Lazy `opts` table reaches `resession.setup`.
- Full configuration loads with no saved state and with a persisted `jb` state.
- `:colorscheme jb` writes the global state immediately so restoration does not depend on a clean Neovim exit.
