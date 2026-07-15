# Services Log Color Fidelity Design

## Goal

Make the Neovim Services log panel render Spring Boot ANSI output with stable,
field-specific colors comparable to IDE consoles while retaining its normal
`nofile` buffer, log parsing, retention, and process-management behavior.

## Approach

Keep the existing streaming ANSI decoder and extmark renderer. Fix its style
reset semantics, render ANSI faint text as a theme-aware blended foreground,
give ANSI decorations an explicit priority, and rebuild generated highlight
groups after a colorscheme change.

Spring Boot service definitions will explicitly enable application ANSI output
through `SPRING_OUTPUT_ANSI_ENABLED=ALWAYS`. Maven's existing
`-Dstyle.color=always` remains responsible for Maven/Jansi output.

## Components

### ANSI state and rendering

`nvim/lua/services/output.lua` will:

- Explicitly clear `fg`, `bg`, and every attribute for SGR reset (`0`).
- Preserve the existing independent stdout/stderr decoder states.
- Render SGR faint (`2`) by blending the effective foreground toward the
  current `Normal` background.
- Set a stable extmark priority for explicit ANSI styling.
- Track generated highlight definitions and recreate them after `ColorScheme`.

### Spring Boot color policy

`nvim/lua/services/providers/springboot.lua` will add
`SPRING_OUTPUT_ANSI_ENABLED=ALWAYS` to discovered Spring Boot services. This is
required because Services captures output through pipes rather than a TTY.

### Tests

`nvim/tests/services_output_spec.lua` will verify exact extmark ranges across
SGR `0`, `39`, and `49`, split reset sequences, faint color generation, and
highlight recreation after a colorscheme event.

`nvim/tests/services_providers_spec.lua` will verify that discovered Spring Boot
services force application ANSI output.

## Non-goals

- Semantic Spring log highlighting when ANSI is absent.
- Terminal cursor emulation for carriage returns and rich progress displays.
- Filtering, follow mode, stack-trace navigation, or log-level controls.
- Changes to the in-progress Services lifecycle work in the current worktree.

## Success Criteria

- ANSI reset stops foreground and background colors at the correct byte column.
- Spring Boot emits ANSI colors when launched through `vim.system` pipes.
- Faint timestamps are visibly dimmer and remain theme-aware.
- Generated ANSI highlights survive colorscheme changes.
- All Services tests pass without modifying unrelated worktree changes.
