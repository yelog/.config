# IGit version selection

Kitty's Cmd+G and every Neovim IGit opening use the same selected executable.

```sh
ig-use stable   # Installed release (the default)
ig-use debug    # Local build
ig-use status   # Selection, entry path, resolved executable, and version
ig-use path     # Resolved executable only; used by Kitty and Neovim
```

The binaries remain at their existing locations:

| Selection | Entry |
| --- | --- |
| stable | `~/.local/bin/ig` |
| debug | `~/workspace/tui/igit/target/debug/ig` |

Build the debug executable explicitly when needed:

```sh
cargo build --locked --manifest-path "$HOME/workspace/tui/igit/Cargo.toml" --bin ig
```

The selection is an atomically replaced symlink at
`${XDG_STATE_HOME:-$HOME/.local/state}/igit/launcher/current`. It points to the
selected entry, so installer-managed stable upgrades continue to work. `path`
follows the full link chain before returning the executable. Switching does not
modify the global `ig`/`igit` installation links or the configuration repository.
Manual `ig` and `igit` commands continue to use the installed release.

Both clients resolve the selection on each open, with a one-second deadline.
Unavailable selections produce an error; they never silently fall back to another
version. Missing state defaults to stable. A failed switch preserves the previous
selection. Selectors do not build IGit automatically.

From inside Neovim, use `:!ig-use debug`, `:!ig-use stable`, or `:!ig-use status`.
The plugin accepts a command callback and includes its resolved executable in the
session identity. Stable and debug retain separate jobs; switching back resumes
the corresponding existing session. Cmd+G hides the Neovim terminal without
stopping its process. Quit with IGit's `q` before testing a rebuilt binary at the
same path. Existing IGit processes keep running their original build.

After first installing this configuration, restart existing Neovim instances once
to load the callback support and configuration. Subsequent version switches need
no Neovim or Kitty restart. Kitty loads its updated kitten on the next Cmd+G.

For a new machine, install the CLI link once (without replacing an existing file):

```sh
chmod +x "$HOME/.config/igit/launcher.py"
mkdir -p "$HOME/.local/bin"
ln -s "$HOME/.config/igit/launcher.py" "$HOME/.local/bin/ig-use"
ig-use stable
```

## Pane maximize

Cmd+Ctrl+F gives the focused embedded IGit terminal priority. Kitty's zoom script
resolves its source window and asks that Neovim instance to forward the shortcut
directly to the IGit job before changing any outer layout. IGit maximizes or
restores its current pane; the Neovim float keeps its size, and other Kitty
windows remain tiled. Tab still switches IGit panes. Log keeps its tiled layout.

Outside an IGit terminal, the existing Kitty stack and Neovim SmartZoom
synchronization remains available. Direct shortcuts and the script's RPC request
share `nvim/lua/custom/igit_terminal.lua`. The script is read on every invocation;
existing Neovim instances load the helper on demand. A stopped IGit job reports
that it must be reopened instead of maximizing its parent window.

Run selector, Kitty, and terminal-routing tests from the configuration repository:

```sh
python3 -m unittest discover -s igit/tests -v
python3 -m unittest discover -s kitty/tests -v
nvim --headless -u NONE -l nvim/tests/igit_terminal_spec.lua
```

The local plugin tests run from `~/workspace/vi/igit.nvim`:

```sh
nvim --headless -u NONE -l tests/run.lua
```
