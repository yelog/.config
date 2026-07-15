# DAP Visual Style Design

## Goal

Make nvim-dap breakpoints and the current stopped line immediately recognizable in the existing transparent TokyoNight interface without adding a UI or virtual-text dependency.

## Current State

`<Space>db` maps directly to `dap.toggle_breakpoint` from `mfussenegger/nvim-dap`. The current setup leaves nvim-dap's default `B` and `->` signs styled as `SignColumn`. The default stopped sign points its line highlight at `debugPC`, which is empty in the active configuration, so the execution line has no useful visual distinction.

## Design

Create a small `custom.dap_style` module shared by the nvim-dap and TokyoNight plugin specifications.

- TokyoNight supplies semantic highlight groups from its palette: red for ordinary breakpoints, orange for conditional breakpoints, blue for log points, muted red for rejected breakpoints, and yellow for the stopped location.
- The stopped line uses a low-saturation yellow blend against the active TokyoNight background. Breakpoints use sign and number highlights only, avoiding repeated full-line backgrounds.
- nvim-dap defines compact single-cell signs: `●`, `◆`, `×`, `◌`, and `▶`. Each sign uses its semantic highlight for the glyph and line number. `DapStopped` uses `DapStoppedLine` for its line highlight instead of the unstyled `debugPC` group.

## Scope

- Keep all existing DAP mappings, adapters, session behavior, and terminal integration.
- Do not add `nvim-dap-ui` or `nvim-dap-virtual-text`.
- Keep the existing `signcolumn=auto` behavior so the editor layout does not widen outside active debugging.

## Verification

- A headless style spec checks the sign glyphs and semantic highlight assignments.
- Existing Java Debug and Services specs continue to pass.
- A full config load confirms the DAP configuration and TokyoNight integration are valid.
