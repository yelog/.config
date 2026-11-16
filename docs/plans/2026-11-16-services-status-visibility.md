# Services Status Visibility Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make ready services and their ports immediately recognizable in the existing Neovim Services list.

**Architecture:** Keep process and readiness detection unchanged. Give the list its own theme-derived semantic highlights, distinguish states with Unicode symbols, and reserve the right edge for status details before fitting the service name.

**Tech Stack:** Lua, Neovim buffers/extmarks, existing Services runtime and headless Lua specs.

---

## Design

The current ready port uses `DiagnosticInfo`, which JB renders as unused-code gray. Running and stopped services both use `o`; long names can also push the port outside the unwrapped list window.

| State | Symbol | Detail | Emphasis |
| --- | --- | --- | --- |
| Ready with port | `●` | `:8080` | Theme success green, bold |
| Ready without port | `●` | `ready` | Theme success green, bold |
| Starting / not ready | `◔` | `starting` | Theme warning color |
| Stopping | `◒` | `stopping` | Theme warning color |
| Restart pending | `◒` | `restarting` | Theme warning color |
| Failed | `×` | `failed` | Theme error color, bold |
| Debugging | `◆` | `debugging` | Theme informational sign color |
| Stopped | `○` | `stopped` | Muted text |

Keep service names at normal contrast. Align details at the right with one cell of padding. Truncate long names with an ellipsis using display width, preserving space for status. Keep the existing list/log split ratio and selection behavior.

Use foreground-only semantic highlights so the selected row remains visible. Refresh highlights on `ColorScheme`; refresh row layout on list-window resize. Use shape and status text alongside color.

## Task 1: Cover visible status behavior

**Files:** Create `nvim/tests/services_panel_style_spec.lua`.

Exercise real list rendering with the existing runtime and synthetic service states, without starting processes. Verify readiness gating, distinct state symbols, port highlight ranges, UTF-8 names, aligned details, narrow widths, resizing, selection preservation, and theme changes.

Run:

```sh
nvim --headless -u NONE -i NONE -l nvim/tests/services_panel_style_spec.lua
```

Expected before implementation: failure on the ready-service presentation.

## Task 2: Implement the list presentation

**Files:** Modify `nvim/lua/services/panel.lua`.

Create Services-specific highlights from diagnostic colors and keep bold emphasis independent from the global diagnostic groups. Replace ASCII status symbols, compute highlight offsets in bytes, and fit the name by display cells after reserving status space. Re-render only when the list window width changes.

Run the focused spec and `nvim/tests/services_panel_spec.lua`; both must pass.

## Task 3: Verify integration and appearance

Run the existing `nvim/tests/services_*_spec.lua` checks in isolated headless Neovim sessions. Inspect the rendered list with JB, a light theme, and a narrow window, including the selected row. Review the final diff and whitespace without changing unrelated work.

Do not restart running services or commit changes.

## Verification Results

- All 11 `services_*_spec.lua` suites pass, including the new presentation coverage.
- The new spec covers all service states, readiness without a port, Chinese names, 60/26/14/12/8/2-cell panels, resize focus preservation, terminal colors, and colorscheme changes.
- Real Neovim TUI captures pass for the original and updated JB dark layouts, mixed service states, JB light, and a 28-cell panel. The selected port retains the cursor-line background and its bold success foreground.
- On the selected JB dark row, measured port contrast changes from 3.42:1 (`#6F737A` on `#1F2024`) to 5.96:1 (`#6AAB73` on `#1F2024`). JB light gives 4.89:1 for the ready port.
- `git diff --check` and StyLua validation of the new spec pass. The existing panel and panel spec already fail whole-file StyLua checks at `HEAD`; their existing formatting is preserved.
- The original panel spec now uses a 200-column viewport so its full-name checks run at the intended desktop panel width. Narrow-window behavior is covered separately.

Preview artifacts: `/Users/yelog/.codex/visualizations/2026/11/16/01a1e2e7-7998-78e0-b2be-e1e264a36120/services-status-comparison.png` and `services-status-validation.png` in the same directory.
